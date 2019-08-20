#!/usr/bin/env sh

# podman_pause_unpause.sh demo script.
# This script will demonstrate at an introductory level
# the use of the podman pause and unpause commands.
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
    rpm -q podman >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the podman package to be installed
	exit 1
    fi
    clear
}

intro() {
    echo_color "\`podman pause\` Demo"
    echo
    echo_color "Available at https://github.com/containers/Demos/podman_cli/podman_pause.sh"
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
    echo_color "Let's pull the alpine image"
    echo
    read_color "podman pull alpine"
    podman pull alpine

    echo
    echo_color "Let's pull the busybox image"
    echo
    read_color "podman pull busybox"
    podman pull busybox 

    echo
    echo_color "Let's look at the images"
    echo
    read_color "podman images"
    podman images

    echo
    read -p "Enter to continue"
    clear
}

podman_do_pause_demo() {

    echo_color "Let's create and run an alpine container for 10 minutes."
    echo
    read_color "podman run --detach --name alpinectr alpine sh -c 'while true ;do sleep 600 ; done'"
    podman run --detach --name alpinectr alpine sh -c 'while true ;do sleep 600 ; done'
    
    echo
    echo_color "Let's create and run a busybox container for 10 minutes."
    echo
    read_color "podman run --detach --name busyboxctr busybox sh -c 'while true ;do sleep 600 ; done'"
    podman run --detach --name busyboxctr busybox sh -c 'while true ;do sleep 600 ; done'

    echo
    echo_color "Let's look at the containers"
    echo
    read_color "podman ps --all"
    podman ps --all

    echo
    echo_color "Let's pause the busyboxctr.  This will cause runc to suspend all of the"
    echo_color "processes associated with the container."
    echo
    read_color "podman pause busyboxctr"
    podman pause busyboxctr

    echo
    echo_color "Let's look at the containers, busyboxctr should show 'Paused' now."
    echo
    read_color "podman ps --all"
    podman ps --all
    
    echo
    echo_color "Let's pause the alpinectr.  This will cause runc to suspend all of the"
    echo_color "processes associated with the container."
    echo
    read_color "podman pause alpinectr"
    podman pause alpinectr

    echo
    echo_color "Let's look at the containers, busyboxctr and alpinectr should both "
    echo_color "show 'Paused' now."
    echo
    read_color "podman ps --all"
    podman ps --all

}

podman_do_unpause_demo() {

    echo
    echo_color "Now let's use the 'podman unpause' command to unpause the containers."
    echo
    read_color "podman unpause --help"
    podman unpause --help
    
    echo
    echo_color "Let's unpause the busyboxctr.  This will cause runc to unsuspend all of the"
    echo_color "processes associated with the container."
    echo
    read_color "podman unpause busyboxctr"
    podman unpause busyboxctr

    echo
    echo_color "Let's look at the containers, busyboxctr should show 'Up' now."
    echo
    read_color "podman ps --all"
    podman ps --all
    
    echo
    echo_color "Let's unpause the alpinectr.  This will cause runc to unsuspend all of the"
    echo_color "processes associated with the container."
    echo
    read_color "podman unpause alpinectr"
    podman unpause alpinectr

    echo
    echo_color "Let's look at the containers, busyboxctr and alpinectr should both "
    echo_color "show 'Up' now."
    echo
    read_color "podman ps --all"
    podman ps --all

}

clean_images_and_containers() {

    echo
    echo_color "Time to clean up!"
    read_color "podman rm --all --force"
    podman rm --all --force
    echo
    read_color "podman rmi --all --force"
    podman rmi --all --force

    echo
    read -p "Enter to continue"
}

setup

intro

version

podman_pull_images

podman_do_pause_demo

podman_do_unpause_demo

clean_images_and_containers

read -p "End of Demo!!!"
echo
echo "Thank you!"
