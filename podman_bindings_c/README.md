# Podman Go bindings exported to C

## Sample Application for Podman Go Bindings via C shared library

This directory contains a sample application to run Podman operations in
external applications via a set of Go bindings which are later exported 
as C shared library. Due to a limitation of such export, wrappers are
needed around original Go bindings.

There's a single Go file, which uses the Podman Go bindings to provide
interface to execute following steps from C application:

1. Pull Image
2. List Images
3. Start Container
4. List Containers
5. Inspect Container
6. Stop Container

There is example main.c which demonstrates the usage of above operations.

### Running the application

1. Clone the repo and enter to the directory.

2. Ensure podman.socket is activated
```bash
$ systemctl --user start podman.socket
```

3. Start service (here using podman command)
```bash
$ podman system service -t 0
```

4. Build go wrapper library (this step will generate C header file as well)
```bash
$ go build -buildmode=c-shared -o libpodc.so libpodc.go
```

5. Build example C application
```bash
$ gcc -O2 -L. -Wl,-rpath=. -Wall -o main main.c -lpodc
```

6. Run it
```bash
$ ./main
Trying to pull registry.fedoraproject.org/fedora-minimal:latest...
Getting image source signatures
Copying blob sha256:2fa61fedb54d576e17d9129a27fbd3c1ff8503b1e0c45622ba8de6a51fb6a9ef
Copying config sha256:fa011f8784baff6b77fc56152b5024c368809c0f4c6b1279dbd9b173f534028a
Writing manifest to image destination
Storing signatures
Listing images...
[registry.fedoraproject.org/fedora-minimal:latest]
INFO[0004] Going to start container "62da10cfe0ff54c56631f3666102bf1e978b2e46263e0434ee4cb0f843def760" 
Ret code: 0. Status of the container with imgName: registry.fedoraproject.org/fedora-minimal:latest is: running
Stop container reported status: 0
```
### Additional info
1. Go wrapper library is based on demo application: https://github.com/containers/Demos/tree/master/podman_go_bindings
2. For go troubleshooting refer to: https://podman.io/blogs/2020/08/10/podman-go-bindings.html
