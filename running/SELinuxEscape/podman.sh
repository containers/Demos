#!/usr/bin/env sh

# podmah.sh demo script.
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

setup() {
    rpm -q podman audit >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the podman and audit packages be installed
	exit 1
    fi
    command -v docker > /dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the docker package be installed
	exit 1
    fi
    sudo systemctl restart auditd 2> /dev/null
    sudo systemctl restart docker
    chcon -t container_file_t breakout.sh
    chmod +x breakout.sh
    clear
}

audit() {
    echo ""
    echo_color "Lets look at the audit log to see what SELinux is reporting"
    echo
    read_color "--> sudo ausearch -m avc -ts recent |  grep shadow | tail -1 | grep --color=auto 'system_u:system_r:container_t:s0[^ ]*'"
    echo
    sudo  ausearch -m avc -ts recent |  grep shadow | tail -1 | grep --color=auto 'system_u:system_r:container_t:s0[^ ]*'
    echo ""
    echo
    read_color "--> sudo ausearch -m avc -ts recent |  grep docker | tail -1 | grep --color=auto 'docker'"
    echo
    sudo  ausearch -m avc -ts recent |  grep docker | tail -1 | grep --color=auto 'docker'
    echo ""
    read -p "--> clear"
    clear
}

run() {
    echo_color "Run Container with SELinux Breakout"
    echo
    read_color "--> sudo podman run -e HOME=\$HOME -rm -ti -v /:/host fedora chroot /host \${PWD}/breakout.sh"
    sudo podman run -e HOME=$HOME -rm -ti -v /:/host fedora chroot /host ${PWD}/breakout.sh
    read -p "--> clear"
    clear
}

setup

run

audit

read -p "End of Demo"
echo "Thank you!"
