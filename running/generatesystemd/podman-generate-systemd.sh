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

cleanup() {
    echo_bright "--> cleanup"
    echo ""
    podman stop -f -t 0 topservice 2> /dev/null
    podman rm -f topservice 2> /dev/null
    rm ~/.config/systemd/user/sometop.service
}

cmd() {
    command=$*
    read_bright "--> $command"
    $command
    echo ""
}

trap cleanup EXIT
podman_generate_systemd() {
    clear
    read_yellow  "Let's create a systemd service to run a container image"
    echo ""

    read_bright "--> podman run -ti ubi8-init"
    podman run -ti ubi8-init
    echo ""

    cmd clear
    
    cmd podman generate systemd --help

    read_yellow "Now I will create a container running top"
    read_bright "--> podman create --name topservice alpine:latest top"
    podman create --name topservice alpine:latest top
    echo ""

    read_bright "--> podman generate systemd --name topservice > ~/.config/systemd/user/sometop.service"
    podman generate systemd --name topservice > ~/.config/systemd/user/sometop.service
    echo ""

    cmd clear
    
    cmd less ~/.config/systemd/user/sometop.service

    clear
    
    cmd systemctl --user daemon-reload

    cmd podman ps

    read_yellow "when you start the service, you start the container"

    cmd systemctl --user start sometop.service

    cmd podman ps

    read_yellow "when you stop the service, you stop the container"

    cmd systemctl --user stop sometop.service

    cmd podman ps

    cmd podman logs topservice

    cmd clear
}

podman_generate_systemd
