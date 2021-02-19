package main

// #include <stdio.h>
// #include <stdlib.h>
// #include <string.h>

import "C"

import (
	"context"
	"fmt"
	"os"

	"github.com/containers/podman/v2/libpod/define"
	"github.com/containers/podman/v2/pkg/bindings"
	"github.com/containers/podman/v2/pkg/bindings/containers"
	"github.com/containers/podman/v2/pkg/bindings/images"
	"github.com/containers/podman/v2/pkg/domain/entities"
	"github.com/containers/podman/v2/pkg/specgen"
)

//has to be global
var ctx context.Context

//simple handler to translate errors
func cErrorHandler(err error) int {
	if err != nil {
		fmt.Println(err)
		return -1
	}
	return 0
}

//export findSocket
func findSocket() *C.char {
	sock_dir := os.Getenv("XDG_RUNTIME_DIR")
	socket := "unix:" + sock_dir + "/podman/podman.sock"
	return C.CString(socket)
}

//export newConnection
func newConnection(socket *C.char) int {
	var err error
	ctx, err = bindings.NewConnection(context.Background(), C.GoString(socket))
	return cErrorHandler(err)
}

//export pullImage
func pullImage(image *C.char) int {
	_, err := images.Pull(ctx, C.GoString(image), entities.ImagePullOptions{})
	return cErrorHandler(err)
}

//export listImages
func listImages() int {
	imageSummary, err := images.List(ctx, nil, nil)
	if err != nil {
		return cErrorHandler(err)
	}
	var names []string
	for _, i := range imageSummary {
		names = append(names, i.RepoTags...)
	}
	fmt.Println("Listing images...")
	fmt.Println(names)
	return cErrorHandler(nil)
}

//export createContainer
func createContainer(image *C.char) (*C.char, int) {
	s := specgen.NewSpecGenerator(C.GoString(image), false)
	s.Terminal = true
	r, err := containers.CreateWithSpec(ctx, s)
	if err != nil {
		return C.CString(""), cErrorHandler(err)
	}
	return C.CString(r.ID), cErrorHandler(nil)
}

//export startContainer
func startContainer(id *C.char) int {
	err := containers.Start(ctx, C.GoString(id), nil)
	return cErrorHandler(err)
}

//export waitForRunning
func waitForRunning(id *C.char) int {
	running := define.ContainerStateRunning
	_, err := containers.Wait(ctx, C.GoString(id), &running)
	return cErrorHandler(err)
}

//export inspectContainer
func inspectContainer(id *C.char) (*C.char, *C.char, int) {
	ctrData, err := containers.Inspect(ctx, C.GoString(id), nil)
	if err != nil {
		return C.CString(""), C.CString(""), cErrorHandler(err)
	}
	return C.CString(ctrData.ImageName), C.CString(ctrData.State.Status), cErrorHandler(nil)
}

//export stopContainer
func stopContainer(id *C.char) int {
	err := containers.Stop(ctx, C.GoString(id), nil)
	return cErrorHandler(err)
}

func main() {
}
