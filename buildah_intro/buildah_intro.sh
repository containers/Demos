#!/bin/sh

# buildah_intro.sh demo script.
# This script will demonstrate at an introductory level
# for Buildah basic concepts and uses.  Also requires
# the Docker and Podman packages to be installed.

setup() {
    rpm -q podman >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the podman package to be installed
	exit 1
    fi
    rpm -q buildah >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the buildah package to be installed
	exit 1
    fi
    command -v docker > /dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the docker package to be installed
	exit 1
    fi
    sudo systemctl restart docker
    clear
}

intro() {
    read -p "Buildah Demos!"
    echo
}

version() {
    # Buildah version inside a container
    echo "Check the Buildah version"
    echo
    read -p "buildah version"
    echo
    buildah version
    echo

    # Buildah info inside a container
    echo
    echo "Check the Buildah info"
    echo
    read -p "buildah info"
    echo
    buildah info

    echo
    read -p "Enter to continue"
    clear
}

buildah_first_image() {
    echo "Let's create our very first container image"
    echo
    read -p "sudo buildah pull alpine"
    sudo buildah pull alpine

    echo
    echo "Let's look at the image"
    echo
    read -p "sudo buildah images"
    sudo buildah images

    echo
    echo "Create a container from the image"
    echo
    read -p "sudo buildah from docker.io/library/alpine"
    sudo buildah from docker.io/library/alpine

    echo
    echo "Look at the container"
    echo
    read -p "sudo buildah containers"
    sudo buildah containers

    echo
    read -p "Enter to continue"
    clear
}

buildah_using_from_scratch() {

    echo "Create an empty image from 'scratch'"
    echo
    read -p "newcontainer=\$(sudo buildah from scratch)"
    newcontainer=$(sudo buildah from scratch)
    echo

    echo
    echo "Now mount the container saving the mount point"
    echo
    read -p "scratchmnt=\$(sudo buildah mount \$newcontainer)"
    scratchmnt=$(sudo buildah mount $newcontainer)

    echo
    echo "Show the location of the mount point"
    echo
    read -p "echo \$scratchmnt"
    echo $scratchmnt

    echo
    echo "Show the contents of the mountpoint"
    echo
    read -p "sudo ls \$scratchmnt"
    sudo ls $scratchmnt
    read -p "Enter to continue"

    echo
    echo "Install Fedora 29 and coreutils into the container from the host"
    echo
    read -p "sudo dnf install --installroot \$scratchmnt --release 29 bash coreutils --setopt install_weak_deps=false -y"
    sudo dnf install --installroot $scratchmnt --release 29 bash coreutils --setopt install_weak_deps=false -y

    echo
    echo "Show /usr/bin inside of the container"
    echo
    read -p "sudo buildah run \$newcontainer -- ls -alF /usr/bin"
    sudo buildah run $newcontainer -- ls -alF /usr/bin

    echo
    echo "Display contents of runecho.sh"
    echo
    read -p "cat ./runecho.sh"
    cat ./runecho.sh

    echo
    echo "Copy the script into the container"
    echo
    read -p "sudo buildah copy \$newcontainer ./runecho.sh /usr/bin"
    sudo buildah copy $newcontainer ./runecho.sh /usr/bin

    echo
    echo "Set the cmd of the container to the script"
    echo
    read -p "sudo buildah config --cmd /usr/bin/runecho.sh \$newcontainer"
    sudo buildah config --cmd /usr/bin/runecho.sh $newcontainer

    echo
    echo "Let's run the container which will run the script"
    echo
    read -p "sudo buildah run $newcontainer /usr/bin/runecho.sh"
    sudo buildah run $newcontainer /usr/bin/runecho.sh

    echo
    echo "Configure the container added created-by then author information"
    echo
    read -p "sudo buildah config --created-by \"buildahdemo\"  \$newcontainer"
    sudo buildah config --created-by "buildahdemo"  $newcontainer

    echo
    echo
    read -p "sudo buildah config --author \"buildahdemo\" --label name=fedora29-bashecho \$newcontainer"
    sudo buildah config --author "buildahdemo at redhat.com" --label name=fedora29-bashecho $newcontainer

    echo
    echo "Let's inspect the container looking for our new configs"
    echo
    read -p "sudo buildah inspect \$newcontainer"
    sudo buildah inspect $newcontainer

    echo
    echo "Now unmount the container as we're done adding stuff to it"
    echo
    read -p "sudo buildah unmount \$newcontainer"
    sudo buildah unmount $newcontainer

    echo
    echo "Commit the image that we've created"
    echo
    read -p "sudo buildah commit \$newcontainer fedora-bashecho"
    sudo buildah commit $newcontainer fedora-bashecho

    echo
    echo "Check for our image"
    echo
    read -p "sudo buildah images"
    sudo buildah images

    echo
    echo "Remove the container"
    echo
    read -p "sudo buildah rm \$newcontainer"
    sudo buildah rm $newcontainer

    echo
    read -p "Enter to continue"
    clear
}

run_image_in_docker() {
    systemctl restart docker

    echo
    echo "Push our image to the Docker daemon"
    echo
    read -p "sudo buildah push fedora-bashecho docker-daemon:fedora-bashecho:latest"
    sudo buildah push fedora-bashecho docker-daemon:fedora-bashecho:latest

    echo
    echo "Show our image under Docker"
    echo
    read -p "sudo docker images"
    sudo docker images

    echo
    echo "Run our image under Docker"
    echo
    read -p "sudo docker run fedora-bashecho"
    sudo docker run fedora-bashecho

    echo
    read -p "Enter to continue"
    clear
}

buildah_from_dockerfile() {

    echo
    echo "Create image from a Dockerfile and run the container"
    echo "Let's look at our Dockerfile"
    echo
    read -p "cat ./Dockerfile.hello"
    cat ./Dockerfile.hello

    echo
    echo "Let's look at our HelloFromContainer.py"
    echo
    read -p "cat ./HelloFromContainer.py"
    cat ./HelloFromContainer.py

    echo
    echo "Create the \"hello\" image from the Dockerfile"
    echo
    read -p "sudo buildah bud -t hello -f ./Dockerfile.hello ."
    sudo buildah bud -t hello -f ./Dockerfile.hello .

    echo
    echo "Create the container from the image"
    echo
    read -p "sudo buildah from hello"
    sudo buildah from hello

    echo
    echo "Run the container"
    echo
    read -p "sudo buildah run hello-working-container python3 /home/HelloFromContainer.py"
    sudo buildah run hello-working-container python3 /home/HelloFromContainer.py

    echo
    echo "Now a quick advertisement from Podman."
    echo "Let's run the container using Podman."
    echo
    read -p "sudo podman run hello"
    sudo podman run hello


    echo
    read -p "Enter to continue"
    clear
}

buildah_from_dockerfile_rootless() {

    echo
    echo "Now we are going to run buildah rootless"
    echo
    echo "Create image from a Dockerfile and run the container"
    echo "Let's look at our Dockerfile"
    echo
    read -p "cat ./Dockerfile.hello"
    cat ./Dockerfile.hello

    echo
    echo "Let's look at our HelloFromContainer.py"
    echo
    read -p "cat ./HelloFromContainer.py"
    cat ./HelloFromContainer.py

    echo
    echo "Create the \"hello\" image from the Dockerfile"
    echo
    read -p "buildah bud -t hello -f ./Dockerfile.hello ."
    buildah bud -t hello -f ./Dockerfile.hello .

    echo
    echo "Create the container from the image"
    echo
    read -p "buildah from hello"
    buildah from hello

    echo
    echo "Run the container"
    echo
    read -p "buildah run hello-working-container python3 /home/HelloFromContainer.py"
    buildah run hello-working-container python3 /home/HelloFromContainer.py

    echo
    echo "Now a quick advertisement from Podman."
    echo "Let's run the container using Podman."
    echo
    read -p "podman run hello"
    podman run hello


    echo
    read -p "Enter to continue"
    clear
}

clean_images_and_containers() {

    read -p "sudo buildah rm -a"
    sudo buildah rm -a
    echo
    read -p "sudo buildah rmi -a -f"
    sudo buildah rmi -a -f

    echo
    read -p "Enter to continue"
    clear
}

setup

intro

version

buildah_first_image

buildah_using_from_scratch

run_image_in_docker

buildah_from_dockerfile

clean_images_and_containers

buildah_from_dockerfile_rootless

read -p "End of Demo!!!"
echo
echo "Thank you!"
