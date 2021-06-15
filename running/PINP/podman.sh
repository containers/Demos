#!/bin/sh

# podmah.sh demo script.
# This script will demonstrate running podmain within a container
# on the security features.

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

exec_command() {
    echo
    read_bright "$@"
    $@
}

# headings
read_yellow() {
    read -p "${bold}${yellow}$1${reset}"
}

PODMANIMAGE=quay.io/podman/testing
IMAGE=registry.access.redhat.com/ubi8-micro:latest

setup() {
    rpm -q podman docker-ce >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the podman and docker-ce packages be installed
	exit 1
    fi
    sudo systemctl start docker
    sudo docker pull -q ${PODMANIMAGE}
    sudo podman pull -q ${PODMANIMAGE}
    podman pull  -q ${PODMANIMAGE}
    clear
}

version() {
    # Podman inside a container
    read -p "podman version"
    echo ""
    podman version
    echo ""
}


rootfull_privileged() {
    echo ""
    echo ""
    read_bright "rootfull privileged"
    exec_command "sudo podman run --rm --privileged ${PODMANIMAGE} podman run ${IMAGE} echo hello"

    echo ""
    read_bright "rootfull docker privileged"
    exec_command "sudo docker run --rm --privileged ${PODMANIMAGE} podman run ${IMAGE} echo hello"
}

rootfull_rootfull_less_privs() {
    echo ""
    echo ""
    read_bright "rootfull rootfull less privs"
    exec_command "sudo podman run --cap-add=sys_admin,mknod --device=/dev/fuse --security-opt label=disable ${PODMANIMAGE} podman run ${IMAGE} echo hello"
}

rootfull_volume_privileged() {
    echo ""
    echo ""
    read_bright "rootfull volume privileged"

    mkdir -p mycontainers
    exec_command "sudo podman run -v ./mycontainers:/var/lib/containers --rm --privileged ${PODMANIMAGE} podman run ${IMAGE} echo hello"
}

rootless_privileged() {
    echo ""
    echo ""
    read_bright "rootless privileged"
    exec_command "podman run --rm --privileged ${PODMANIMAGE} podman run ${IMAGE} echo hello"
}

rootfull_rootless() {
    echo ""
    echo ""
    read_bright "rootfull rootless"
    exec_command "sudo podman run --device /dev/fuse --user podman --security-opt label=disable --rm ${PODMANIMAGE} podman run ${IMAGE} echo hello"

    echo ""
    read_bright "rootfull docker rootless"

    tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
    sudo chown 1000:1000 ${tmp_dir}
    exec_command "sudo docker run --device /dev/fuse -v ${tmp_dir}:/home/podman/.local/share/containers/storage --user podman --security-opt label=disable --security-opt seccomp=unconfined --rm ${PODMANIMAGE} podman unshare cat /proc/self/uid_map"
    IMAGE=docker.io/library/alpine:latest
    exec_command "sudo docker run --device /dev/fuse -v ${tmp_dir}:/home/podman/.local/share/containers/storage --user podman --security-opt label=disable --security-opt seccomp=unconfined --rm ${PODMANIMAGE} podman run ${IMAGE} echo hello"
    sudo rm -rf ${tmp_dir}
}

rootless_rootless() {
    echo ""
    echo ""
    read_bright "rootless rootless"
    exec_command "podman run --user podman --device /dev/fuse --security-opt label=disable --rm ${PODMANIMAGE} podman run ${IMAGE} echo hello"
}

setup
version
rootfull_privileged
rootfull_rootfull_less_privs
rootfull_volume_privileged
rootless_privileged
rootfull_rootless
rootless_rootless

read -p "End of Demo"
echo "Thank you!"
