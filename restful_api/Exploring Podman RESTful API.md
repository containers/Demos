# Exploring Podman RESTful API using Python and Bash

You may have heard Podman V2 has a new [RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer) [API](https://docs.podman.io/en/latest/_static/api.html). This document will demonstrate the API using code examples in Python and shell commands. Additional notes are included in the code comments. The provided code was written to be clear vs. production quality.

## Requirements

 - You have Python >3.4 installed
 - You have installed the Python [requests](https://requests.readthedocs.io/en/master/) library
     -  [installation notes](https://requests.readthedocs.io/en/master/user/install/#install)
 - An IDE for editing Python is recommended
 - Two terminal windows: one for running the Podman service and reviewing debugging information, the second window to run scripts
 - Usage of curl and [jq](https://stedolan.github.io/jq/) commands are demonstrated

## Getting Started

### The Service

For these examples, we are running the Podman service as a normal user and on an unsecured TCP/IP port number.

For production, the Podman service should use systemd's [socket activation protocol](https://www.freedesktop.org/software/systemd/man/systemd.socket.html). This allows Podman to support clients without additional daemons and secure the access endpoint.

The following command will run the Podman service on port 8080 without timing out. You will need to type ^C into this terminal window when you are finished with the tutorial.

```shell
podman system service tcp:localhost:8080 --log-level=debug --time=0
```

In addition to the TCP socket demonstrated above the Podman service supports running under systemd's socket activation protocol and unix domain sockets (UDS).

## Python Code

### Info Resource

The following will show us information about the Podman service and host.

```python
import json
import requests

response = requests.get("http://localhost:8080/v1.40.0/libpod/info")
```

#### Deep Dive

 - `requests.get()`  call the requests library to pass the URL to the Podman service using the GET HTTP method
    - The requests library provides helper methods for all the popular HTTP methods 
 - `http://localhost:8080` matches the Podman service invocation above
 - `/v1.40.0` denotes the API version we are using
 - `/libpod` denotes we expect the service to provide a libpod specific return payload
   - Not using this element causes the server to return a compatible payload
 - `/info` is the resource we are querying

Interesting to read, but without output how do we know it worked? 

#### Getting output

Append the lines below, and you can now see the version of Podman running on the host.

```python

response.raise_for_status()

info = json.loads(response.text)
print(info.version.Version)
```

 - `raise_for_status()` will raise an exception if status code is not between 200 and 399.
 - `json.loads()` decodes the body of the HTTP response into an object/dictionary.
 
When executed, the output is:

```text
2.1.0-dev
```

The following works from the shell:

```shell
$ curl -s 'http://localhost:8080/v1.40.0/libpod/info' | jq .version.Version

"2.1.0-dev"
```

### Listing Containers

```python
import json
import requests

response = requests.get("http://localhost:8080/v1.40.0/libpod/containers/json?all=true")
response.raise_for_status()

ctnrs = json.loads(response.text)
for c in ctnrs:
    print(c.Id)
```

`json.loads()` decodes the HTTP body into an array of objects/dictionaries, the program then prints each container Id.

```shell
$ curl -s 'http://localhost:8080/v1.40.0/libpod/containers/json?all=true' | jq .[].Id

"81af11ef7188a826cb5883330525e44afea3ae82634980d68e4e9eefc98d6f61"
```

If the query parameter "all=true" had not been provided, then only the running containers would have been listed. The resource queries and parameters for the API are documented at [https://docs.podman.io/en/latest/_static/api.html](https://docs.podman.io/en/latest/_static/api.html)

### Something Useful

We've looked at a couple examples but how about something a little more useful? You have finished developing the next great container, the script below will remove everything from your local storage.
(If you want to save on typing [clean_storage.py](https://github.com/containers/Demo/blob/master/restful_api/clean_storage.py).)

```python
#!/usr/bin/env python
import json

import requests

# Clean up local storage by removing all containers, pods, and images.  Any error will
#   abort the process

confirm = input("Really delete all items from storage? [y/N] ")
if str(confirm).lower().strip() != 'y':
    exit(0)

# Query for all pods in storage
response = requests.get("http://localhost:8080/v1.40.0/libpod/pods/json")
response.raise_for_status()

pods = json.loads(response.text)
# Workaround for https://github.com/containers/podman/issues/7392
if pods is not None:
    for p in pods:
        # For each container: delete container and associated volumes
        response = requests.delete(f"http://localhost:8080/v1.40.0/libpod/pods/{p['Id']}?force=true")
        response.raise_for_status()
    print(f"Removed {len(pods)} pods and associated objects")
else:
    print(f"Removed 0 pods and associated objects")

# Query for all containers in storage
response = requests.get("http://localhost:8080/v1.40.0/libpod/containers/json?all=true")
response.raise_for_status()

ctnrs = json.loads(response.text)
for c in ctnrs:
    # For each container: delete container and associated volumes
    print(c.keys())
    response = requests.delete(f"http://localhost:8080/v1.40.0/libpod/containers/{c['Id']}?force=true&v=true")
    response.raise_for_status()
print(f"Removed {len(ctnrs)} containers and associated objects")

# Query for all images in storage
response = requests.get("http://localhost:8080/v1.40.0/libpod/images/json")
response.raise_for_status()

imgs = json.loads(response.text)
for i in imgs:
    # For each image: delete image and any associated containers
    response = requests.delete(f"http://localhost:8080/v1.40.0/libpod/images/{i['Id']}?force=true")
    response.raise_for_status()
print(f"Removed {len(imgs)} images and associated objects")

```

## Summary

I hope you find this helpful. The [API documentation](https://docs.podman.io/en/latest/_static/api.html) provides you with all the resources and required methods.  The input and output bodies are included as well as the status codes.
 
The Podman code is under heavy development and we would like your input with [github](https://github.com/containers/podman.git)  [issues](https://github.com/containers/podman/issues) and [pull requests](https://github.com/containers/podman/pulls).
