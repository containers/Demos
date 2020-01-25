#!/bin/sh

# mirror.sh demo script.
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

crio_mirrors() {
    read_yellow "CRI-O with mirrors"
    echo ""

    read_bright "--> sudo skopeo copy --dest-tls-verify=false docker://docker.io/umohnani/myalpine docker://localhost:5000/myrepo/myalpine"
    sudo skopeo copy --dest-tls-verify=false docker://docker.io/umohnani/myalpine docker://localhost:5000/myrepo/myalpine
    echo ""

    read_bright "--> digest=\$(sudo skopeo inspect docker://docker.io/umohnani/myalpine | jq -r '.Digest')"
    digest=$(sudo skopeo inspect docker://docker.io/umohnani/myalpine | jq -r '.Digest')
    digest=sha256:f0a40ed8b03dea6db852d5bf4f0665323579dbd3b646d5d93a2245eb6173203c
    echo "$digest"
    echo ""

    read_bright "--> cat /etc/containers/registries.conf"
    cat /etc/containers/registries.conf
    echo ""

    read_bright "--> ping 4.2.2.2"
    ping 4.2.2.2
    echo ""

    read_bright "--> sudo podman images"
    sudo podman images
    echo ""

    read_bright "--> sudo crictl pull docker.io/umohnani/myalpine@sha256:f0a40ed8b03dea6db852d5bf4f0665323579dbd3b646d5d93a2245eb6173203c"
    sudo podman pull docker.io/umohnani/myalpine@sha256:f0a40ed8b03dea6db852d5bf4f0665323579dbd3b646d5d93a2245eb6173203c
    echo ""

    read_bright "--> sudo podman images"
    sudo podman images
    echo ""

    read_bright "--> POD=\$(sudo crictl runp sandbox_config.json)"
    POD=$(sudo crictl runp sandbox_config.json)
    echo "$POD"
    echo ""

    read_bright "--> CTR=\$(sudo crictl create \$POD container_config.json sandbox_config.json)"
    CTR=$(sudo crictl create "$POD" container_config.json sandbox_config.json)
    echo "$CTR"
    echo ""

    read_bright "--> sudo crictl start \$CTR"
    sudo crictl start "$CTR"
    echo ""

    read_bright "--> sudo crictl ps"
    sudo crictl ps
    echo ""

    read_bright "--> cleanup"
    sudo crictl stopp "$POD" 2> /dev/null
    sudo crictl rmp "$POD" 2> /dev/null
    echo ""

    read_bright "--> clear"
    clear
}

crio_mirrors

read_yellow "Now we reboot the machine"

