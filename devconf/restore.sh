#!/bin/sh

# restore.sh demo script.
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

podman_restore() {
    read_yellow "Podman restore"
    sudo setenforce 0
    echo ""

    read_bright "--> sudo podman container restore --keep myctr"
    sudo podman container restore --keep myctr
    echo "$ctr"
    echo ""

    read_bright "--> sudo podman ps"
    sudo podman ps
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

    read_bright "--> cleanup"
    sudo podman stop -t 0 --all 2> /dev/null
    sudo podman rm -f -all 2> /dev/null
    echo ""

    read_bright "--> clear"
    clear
}

podman_restore

read_yellow "My container was successully restored!"

