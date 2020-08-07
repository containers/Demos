package main

import (
	"context"
	"fmt"
	"os"

	"github.com/containers/libpod/v2/libpod/define"
	"github.com/containers/libpod/v2/pkg/bindings"
	"github.com/containers/libpod/v2/pkg/bindings/containers"
	"github.com/containers/libpod/v2/pkg/bindings/images"
	"github.com/containers/libpod/v2/pkg/domain/entities"
	"github.com/containers/libpod/v2/pkg/specgen"
)

func main() {
	fmt.Println("Welcome to Podman Go bindings tutorial")

	// Get Podman socket location
	sock_dir := os.Getenv("XDG_RUNTIME_DIR")
	socket := "unix:" + sock_dir + "/podman/podman.sock"

	// Connect to Podman socket
	connText, err := bindings.NewConnection(context.Background(), socket)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// Pull Busybox image
	fmt.Println("Pulling Busybox image...")
	_, err = images.Pull(connText, "docker.io/busybox", entities.ImagePullOptions{})
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// Pull Fedora image
	rawImage := "registry.fedoraproject.org/fedora:latest"
	fmt.Println("Pulling Fedora image...")
	_, err = images.Pull(connText, rawImage, entities.ImagePullOptions{})
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// List images
	imageSummary, err := images.List(connText, nil, nil)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	var names []string
	for _, i := range imageSummary {
		names = append(names, i.RepoTags...)
	}
	fmt.Println("Listing images...")
	fmt.Println(names)

	// Container create
	s := specgen.NewSpecGenerator(rawImage, false)
	s.Terminal = true
	r, err := containers.CreateWithSpec(connText, s)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// Container start
	fmt.Println("Starting Fedora container...")
	err = containers.Start(connText, r.ID, nil)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// Wait for container to run
	running := define.ContainerStateRunning
	_, err = containers.Wait(connText, r.ID, &running)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// Container list
	var latestContainers = 1
	containerLatestList, err := containers.List(connText, nil, nil, &latestContainers, nil, nil, nil)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Printf("Latest container is %s\n", containerLatestList[0].Names[0])

	// Container inspect
	ctrData, err := containers.Inspect(connText, r.ID, nil)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Printf("Fedora Container uses image %s\n", ctrData.ImageName)
	fmt.Printf("Fedora Container running status is %s\n", ctrData.State.Status)

	// Container stop
	fmt.Println("Stopping Fedora container...")
	err = containers.Stop(connText, r.ID, nil)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	ctrData, err = containers.Inspect(connText, r.ID, nil)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Printf("Container running status is now %s\n", ctrData.State.Status)
	return

}
