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
