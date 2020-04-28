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

trap cleanup EXIT
podman_generate_systemd() {
    read_yellow  "Let's create a systemd service to run a container image"
    echo ""

    read_yellow "podman generate systemd help menu"
    read_bright "--> podman generate systemd --help"
    podman generate systemd --help
    echo ""

    read_yellow "podman create -d --name topservice alpine:latest top"
    read_bright "--> podman create -d --name topservice alpine:latest top"
    podman create -d --name topservice alpine:latest top
    echo ""

    read_bright "--> podman generate systemd --name topservice > ~/.config/systemd/user/sometop.service"
    podman generate systemd --name topservice > ~/.config/systemd/user/sometop.service
    echo ""

    read_bright "--> check out ~/.config/systemd/user/sometop.service"
    cat ~/.config/systemd/user/sometop.service
    echo ""

    read_bright "--> systemctl --user daemon-reload"
    systemctl --user daemon-reload
    echo ""

    read_bright "--> systemctl --user start sometop.service"
    systemctl --user start sometop.service
    echo ""

    read_bright "--> journalctl --user-unit sometop.service"
    journalctl --user-unit sometop.service | tail
    echo ""

    read_yellow "when you stop the service, you stop the container"
    read_bright "--> systemctl --user stop sometop.service"
    systemctl --user stop sometop.service
    echo ""

    read_bright "--> podman ps -a"
    podman ps -a
    echo ""

    read_yellow "when you start the service, you start the container"
    read_bright "--> systemctl --user start sometop.service"
    systemctl --user start sometop.service
    echo ""

    read_bright "--> podman ps -a"
    podman ps -a
    echo ""

    read_bright "--> podman logs topservice"
    podman logs topservice
    echo ""

    read_bright "--> clear"
    clear
}
podman_generate_systemd
