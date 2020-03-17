#!/bin/sh

# podmah.sh demo script.
# This script will demonstrate a lot of the features of podman, concentrating
# on the security features.

setup() {
    rpm -q podman audit >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the podman, buildah and audit packages be installed
	exit 1
    fi
#    sudo bash -c "> /var/log/audit/audit.log"
    clear
}

syscalls() {
    out=$(sudo awk '/SYSCALL/{print $NF}' /var/log/audit/audit.log  | cut -f2 -d = | sort -u)
    for i in $out; do echo -n \"$i\",; done
    read -p ""
}

version() {
    # Podman inside a container
    read -p "sudo podman version"
    echo ""
    sudo podman version
    echo ""

    # Podman inside a container
    read -p "sudo podman info"
    echo ""
    sudo podman info
}

seccomp() {
    # Podman Generate Seccomp Rules
    read -p "OCI Hooks"
    echo ""

    read -p "--> cat /usr/share/containers/oci/hooks.d/oci-seccomp-bpf-hook-run.json"
    sudo cat /usr/share/containers/oci/hooks.d/oci-seccomp-bpf-hook-run.json
    echo ""
    echo ""

    read -p "--> sudo podman run --annotation io.containers.trace-syscall=/tmp/myseccomp.json fedora ls /"
    sudo podman run --annotation io.containers.trace-syscall=/tmp/myseccomp.json fedora ls /
    echo ""

    read -p "--> sudo cat /tmp/myseccomp.json | json_pp"
    sudo sudo cat /tmp/myseccomp.json | json_pp > /tmp/myseccomp.pp
    cat /tmp/myseccomp.pp
    echo ""

    read -p "--> sudo podman run --security-opt seccomp=/tmp/myseccomp.json fedora ls /"
    sudo podman run --security-opt seccomp=/tmp/myseccomp.json fedora ls /
    echo ""

    read -p "--> sudo podman run --security-opt seccomp=/tmp/myseccomp.json fedora ls -l /"
    sudo podman run --security-opt seccomp=/tmp/myseccomp.json fedora ls -l /
    echo ""

    read -p "--> sudo grep --color SYSCALL=.* /var/log/audit/audit.log"
    sudo sudo grep --color SYSCALL=.* /var/log/audit/audit.log
    echo ""

    syscalls

    read -p "--> sudo vi /tmp/myseccomp.json"
    sudo sudo vi /tmp/myseccomp.json
    echo ""

    read -p "--> sudo podman run --security-opt seccomp=/tmp/myseccomp.json fedora ls -l /"
    sudo podman run --security-opt seccomp=/tmp/myseccomp.json fedora ls -l /
    echo ""

    read -p "--> sudo podman run --annotation io.containers.trace-syscall=/tmp/myseccomp2.json fedora ls -l / > /dev/null"
    sudo podman run --annotation io.containers.trace-syscall=/tmp/myseccomp2.json fedora ls -l / > /dev/null
    echo ""

    read -p "-->     diff -u /tmp/myseccomp.pp /tmp/myseccomp2.pp"
    sudo sudo cat /tmp/myseccomp2.json | json_pp > /tmp/myseccomp2.pp
    diff -u /tmp/myseccomp.pp /tmp/myseccomp2.pp

    read -p "--> clear"
    clear
}

setup
seccomp

read -p "End of Demo"
echo "Thank you!"
