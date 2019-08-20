#!/usr/bin/env sh

# breakout.sh demo script.
# This script will demonstrate a lot of the features of podman, concentrating
# on the security features.

# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
blue=$(tput setaf 4)
reset=$(tput sgr0)

read_color() {
    read -p "${bold}$1${reset}"
}

echo_color() {
    echo "${blue}$1${reset}"
}

run() {
    echo
    echo_color "Inside container show SELinux label"
    echo
    read_color "--> id | grep --color=auto 'system_u:system_r:container_t:s0[^ ]*'"
    id | grep --color=auto 'system_u:system_r:container_t:s0[^ ]*'
    echo ""
    read_color "--> cat/etc/shadow"
    cat /etc/shadow
    echo ""
    read_color "--> touch /var/log/messages"
    touch /var/log/messages
    echo ""
    read_color "--> cd ${HOME}"
    cd $HOME
    echo ""
    read_color "--> ls ${HOME}/.ssh"
    ls ${HOME}/.ssh
    echo ""
    read_color "--> ls /proc/1/"
    ls /proc/1/
    echo ""
    read_color "--> systemctl status docker"
    systemctl status docker
    echo ""
    read_color "--> docker run fedora echo hello"
    docker run fedora echo hello
    echo ""
}

run
