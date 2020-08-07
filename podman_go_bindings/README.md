# Demos - podman_Go_bindings

## Sample Application for Podman Go Bindings

This directory contains a sample application to run Podman operations in
external applications via a set of Go bindings.

There's a single Go file, which uses the Podman Go bindings to run the
following operations:

0. Pull Image
1. List Images
2. Start Container
3. List Containers
4. Inspect Container
5. Stop Container

### Running the application

0. Clone the repo and enter the podman_go_bindings directory.
```bash
$ git clone https://github.com/containers/Demos.git
$ cd Demos/podman_go_bindings
```

1. Ensure podman.socket is activated
```bash
systemctl --user start podman.socket
```

2. Run the application
```bash
$ go run main.go
```
