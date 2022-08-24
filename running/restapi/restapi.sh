#!/bin/sh

# Setting up some colors for helping read the demo output.
bold=$(tput bold)
bright=$(tput setaf 14)
yellow=$(tput setaf 11)
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

setup() {
    sudo systemctl stop docker.socket
    sudo systemctl stop docker.service
}
cleanup() {
    setup
    echo_bright "--> cleanup"
    echo ""
#    podman stop -f -t 0 topservice 2> /dev/null
#    podman rm -f topservice 2> /dev/null
}

trap cleanup EXIT
restapi() {
    clear
    echo_bright  "Let's try out Docker on my machine"
    echo ""

    read_yellow "sudo docker version"
    read_bright "--> sudo docker version"
    sudo docker version

    echo ""

    cmd="sudo systemctl status docker"
    read_bright "--> $cmd"
    $cmd | grep -E --color "Active.*)|"

    echo ""

    cmd="sudo podman --remote version"
    read_bright "--> $cmd"
    $cmd
    echo ""

    cmd="sudo systemctl status podman.socket"
    read_bright "--> $cmd"
    $cmd
    echo ""

    cmd="sudo DOCKER_HOST=unix:///var/run/podman/podman.sock docker version"
    read_bright "--> $cmd"
    $cmd  | grep -E --color "Podman.*|"
    echo ""

    cmd="sudo DOCKER_HOST=unix:///var/run/podman/podman.sock docker info"
    read_bright "--> $cmd"
    $cmd  | grep -E --color "Containers.*|"
    echo ""

    cmd="sudo podman info"
    read_bright "--> $cmd"
    $cmd  | grep -E --color "number.*|"
    echo ""

    cmd="sudo DOCKER_HOST=unix:///var/run/podman/podman.sock docker run registry.access.redhat.com/ubi8-micro printenv"
    read_bright "--> $cmd"
    $cmd | grep -E --color "container=podman|"
    echo ""

    read_bright "Demo Complete"

    clear
}
compose() {
    clear
    echo_bright  "Now let's try out docker-compose in rootless mode"
    echo ""
    echo ""
    cmd="systemctl --user start podman.socket"
    read_bright "--> $cmd"
    $cmd

    echo ""
    cmd="podman --remote version"
    read_bright "--> $cmd"
    $cmd
    echo ""

    cmd="systemctl --user status podman.socket"
    read_bright "--> $cmd"
    $cmd | grep -E --color "/run.*sock|"

    cmd="DOCKER_HOST=unix:///run/user/3267/podman/podman.sock docker run registry.access.redhat.com/ubi8-micro printenv"
    read_bright "--> $cmd"
    eval $cmd | grep -E --color "container=podman|"

    echo ""
    cmd="podman ps"
    read_bright "--> $cmd"
    $cmd
    echo ""

    cmd="DOCKER_HOST=unix:///run/user/3267/podman/podman.sock docker-compose up -d"
    read_bright "--> $cmd"
    eval $cmd

    echo ""
    cmd="podman ps"
    read_bright "--> $cmd"
    $cmd
    echo ""

    cmd="DOCKER_HOST=unix:///run/user/3267/podman/podman.sock docker-compose down"
    read_bright "--> $cmd"
    eval $cmd

    echo ""
    cmd="podman ps"
    read_bright "--> $cmd"
    $cmd
    echo ""
}

setup
restapi
compose
