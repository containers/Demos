#!/bin/sh

# checkpoint.sh demo script.
# This script will demonstrate how checkpoint and restore works in podman

# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
bright=$(tput setaf 14)
yellow=$(tput setaf 11)
red=$(tput setaf 196)
reset=$(tput sgr0)

# commands
read_bright() {
    read -p "${bold}${bright}$1${reset}"
}
echo_bright() {
    echo "${bold}${bright}$1${reset}"
}

# headings
read_yellow() {
    read -p "${bold}${yellow}$1${reset}"
}

# headings
read_red() {
    read -p "${bold}${red}$1${reset}"
}

podman_checkpoint() {
    read_yellow "Podman checkpoint"
    echo ""

    read_bright "--> sudo podman run --tmpfs /tmp --name myctr -d docker://docker.io/yovfiatbeb/podman-criu-test"
    sudo podman run --tmpfs /tmp --name myctr -d docker://docker.io/yovfiatbeb/podman-criu-test
    echo "$ctr"
    echo ""

    read_bright "--> ctr_ip=\$(sudo podman inspect myctr --format {{.NetworkSettings.IPAddress}})"
    ctr_ip=$(sudo podman inspect myctr --format {{.NetworkSettings.IPAddress}})
    echo "$ctr_ip"
    echo ""

    read_bright "--> curl \$ctr_ip:8080/examples/servlets/servlet/HelloWorldExample"
    curl $ctr_ip:8080/examples/servlets/servlet/HelloWorldExample
    echo ""

    read_bright "--> curl \$ctr_ip:8080/examples/servlets/servlet/HelloWorldExample"
    curl $ctr_ip:8080/examples/servlets/servlet/HelloWorldExample
    echo ""

    read_bright "--> sudo podman container checkpoint --keep \$ctr"
    sudo podman container checkpoint --keep myctr
    echo ""

    read_bright "--> sudo podman ps -a"
    sudo podman ps -a
    echo ""
}

podman_checkpoint

read_yellow "Now we reboot the machine"
sudo reboot

