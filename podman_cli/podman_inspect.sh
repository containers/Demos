#!/usr/bin/env sh

# podman_inspect.sh demo script.
# This script will demonstrate at an introductory level
# the use of the podman inspect command.
# Podman must be installed prior to running this script.

 
# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

read_color() {
    read -p "${bold}$1${reset}"
}

echo_color() {
    echo "${cyan}$1${reset}"
}

setup() {
    type podman >/dev/null
    if [ $? != 0 ]; then
	echo $0 requires the podman package to be installed
	exit 1
    fi
    clear
}

intro() {
    echo_color "\`podman inspect\` Demo"
    echo
    echo_color "Available at https://github.com/containers/Demos/podman_cli/podman_inspect.sh"
    echo
}

version() {
   
    echo_color "First check the Podman version"
    echo
    read_color "podman version"
    echo
    podman version
    echo

    echo
    read -p "Enter to continue"
    clear
}

podman_pull_images() {
    echo_color "Let's pull our container image"
    echo
    read_color "podman pull alpine"
    podman pull alpine

    echo
    echo_color "Let's look at the image"
    echo
    read_color "podman images"
    podman images

    echo
    read -p "Enter to continue"
    clear
}

podman_inspect() {
    echo
    echo_color "Let's look at what the inspect command can do"
    echo
    echo_color "Inspect the alpine image"
    echo
    read_color "podman inspect -t image alpine | less"
    podman inspect -t image alpine | less

    echo
    echo_color "Let's create a container to inspect"
    echo
    read_color "podman run --name=myctr alpine  ls /etc/network"
    podman run --name=myctr alpine  ls /etc/network

    echo
    echo_color "Now inspect our container"
    echo
    read_color "podman inspect -t container myctr | less"
    podman inspect -t container myctr | less

    echo
    echo_color "Inspect our latest container"
    echo
    read_color "podman inspect --latest | less"
    podman inspect --latest | less

    echo
    echo_color "Look at the containers ImageName"
    echo
    read_color "podman inspect  -t container --format \"imagename: {{.ImageName}}\" myctr"
    podman inspect  -t container --format "imagename: {{.ImageName}}" myctr

    echo
    echo_color "Look at the containers GraphDriver.Name"
    echo
    read_color "podman inspect  -t container --format \"table {{.GraphDriver.Name}}\" myctr"
    podman inspect  -t container --format "graphdriver: {{.GraphDriver.Name}}" myctr

    echo
    echo_color "Look at the image size using format"
    echo
    read_color "podman inspect -t image --format \"size: {{.Size}}\" alpine"
    podman inspect -t image --format "size: {{.Size}}" alpine

    echo
    read -p "Enter to continue"
    clear
}

clean_images_and_containers() {

    echo
    echo_color "Time to clean up!"
    read_color "podman rm -a -f"
    podman rm -a -f
    echo
    read_color "podman rmi -a -f"
    podman rmi -a -f

    echo
    read -p "Enter to continue"
    clear
}

setup

intro

version

podman_pull_images

podman_inspect

clean_images_and_containers

read -p "End of Demo!!!"
echo
echo "Thank you!"
