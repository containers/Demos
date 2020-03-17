#!/usr/bin/env sh

bold=$(tput bold)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

# podmah.sh demo script.
# This script will demonstrate a new security features of podman

setup() {
    rpm -q podman audit >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the podman, buildah and audit packages be installed
	exit 1
    fi
    command -v docker > /dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the docker package be installed
	exit 1
    fi
    sudo augenrules --load > /dev/null
    sudo systemctl restart auditd 2> /dev/null
    sudo systemctl restart docker
    cat > /tmp/Containerfile <<EOF
FROM ubi8
RUN  dnf -y install iputils
EOF
    podman build -t ping -f /tmp/Containerfile /tmp
    clear
}

ping() {
    read -p "
Dropping capabilities prevents ${bold}ping${reset} command from working.

This demonstration with use show how to drop the NET_RAW Linux capability, and
then how to set a syscall inside of the container, which allows the ping
command to work again.
"
    # Podman ping inside a container
    read -p "podman run ping ping -c 3 4.2.2.2"
    echo ""
    podman run ping ping -c 3 4.2.2.2
    echo ""

    # Podman inside a container
    read -p "podman run ${bold}--cap-drop NET_RAW${reset} ping ping -c 3 4.2.2.2"
    echo ""
    podman run --cap-drop NET_RAW ping ping -c 3 4.2.2.2
    echo ""
    read -p "
Fails because ${bold}NET_RAW${reset} disabled."

    # Podman inside a container
    read -p "
Execute same container with --sysctl 'net.ipv4.ping_group_range=0 1000' enabled

podman run -sysctl --cap-drop NET_RAW ${bold}--sysctl 'net.ipv4.ping_group_range=0 1000'${reset} ping ping -c 3 4.2.2.2"
    echo ""
    podman run -ti --cap-drop NET_RAW --sysctl 'net.ipv4.ping_group_range=0 1000' ping ping -c 3 4.2.2.2
    echo ""
    read -p "end demo"
    clear
}

syscalls() {
    out=$(sudo awk '/SYSCALL/{print $NF}' /var/log/audit/audit.log | grep SYSCALL | cut -f2 -d = | sort -u)
    echo "
"
    for i in $out; do echo -n \"$i\",; done
    echo "
"
    read -p ""
}

seccomp() {
    # Podman Generate Seccomp Rules
    read -p "
Podman Generate Seccomp Rules

This demonstration with use an OCI Hook to fire up a BPF Program to trace
all sycalls generated from a container.  

We will then use the generated seccomp file to lock down the container, only 
allowing the generated syscalls, rather then the system default.
"
    echo ""

    read -p "--> less /usr/share/containers/oci/hooks.d/oci-seccomp-bpf-hook-run.json"
    sudo less /usr/share/containers/oci/hooks.d/oci-seccomp-bpf-hook-run.json
    echo ""
    echo ""

    read -p "--> sudo podman run ${bold}--annotation io.containers.trace-syscall=/tmp/myseccomp.json${reset} fedora ls /"
    sudo podman run --annotation io.containers.trace-syscall=/tmp/myseccomp.json fedora ls /
    echo ""

    read -p "--> sudo cat /tmp/myseccomp.json | json_pp"
    sudo sudo cat /tmp/myseccomp.json | json_pp > /tmp/myseccomp.pp
    less /tmp/myseccomp.pp
    echo ""
    clear
    read -p "--> sudo podman run ${bold}--security-opt seccomp=/tmp/myseccomp.json${reset} fedora ls /"
    sudo podman run --security-opt seccomp=/tmp/myseccomp.json fedora ls /
    echo ""
    read -p ""
    clear
    
    read -p "--> sudo podman run --security-opt seccomp=/tmp/myseccomp.json fedora ${bold}ls -l /${reset}"
    sudo podman run --security-opt seccomp=/tmp/myseccomp.json fedora ls -l /
    echo ""

    read -p "--> sudo grep --color SYSCALL=.* /var/log/audit/audit.log"
    sudo sudo grep --color SYSCALL=.* /var/log/audit/audit.log
    echo ""

    syscalls

    read -p "--> sudo podman run --annotation io.containers.trace-syscall=/tmp/myseccomp2.json fedora ls -l / > /dev/null"
    sudo podman run --annotation io.containers.trace-syscall=/tmp/myseccomp2.json fedora ls -l / > /dev/null
    echo ""

    read -p "--> sudo podman run ${bold}--security-opt seccomp=/tmp/myseccomp2.json${reset} fedora ls -l /"
    sudo podman run --security-opt seccomp=/tmp/myseccomp2.json fedora ls -l /
    echo ""

    read -p "-->     diff -u /tmp/myseccomp.pp /tmp/myseccomp2.pp"
    sudo sudo cat /tmp/myseccomp2.json | json_pp > /tmp/myseccomp2.pp
    diff -u /tmp/myseccomp.pp /tmp/myseccomp2.pp | less
    read -p "End Demo"
    clear
}


containers_conf_ping() {
    read -p "
This demonstration will show how you can specify the default linux capabilities
for all containers on your system.

Then of the demonstration will show ping still running without NET_RAW 
Capability, since containers_conf will automatically set the sycall.
"
cat > containers.conf <<EOF
[containers]

# List of default capabilities for containers. If it is empty or commented out,
# the default capabilities defined in the container engine will be added.
#
default_capabilities = [
    "CHOWN",
    "DAC_OVERRIDE",
    "FOWNER",
    "FSETID",
    "KILL",
    "NET_BIND_SERVICE",
    "SETFCAP",
    "SETGID",
    "SETPCAP",
    "SETUID",
]
EOF
    
    # Podman ping inside a container
    read -p "podman run -d fedora sleep 6000"
    echo ""
    podman run -d fedora sleep 6000
    echo ""

    # Podman ping inside a container
    read -p "podman top -l capeff"
    echo ""
    podman top -l capeff |  grep --color=auto -B 1 NET_RAW
    echo ""

    # Podman ping inside a container
    read -p "cat containers.conf"
    echo ""
    cat containers.conf
    echo ""

    # Podman ping inside a container
    read -p "CONTAINERS_CONF=containers.conf podman run -d fedora sleep 6000"
    echo ""
    CONTAINERS_CONF=containers.conf podman run -d fedora sleep 6000
    echo ""

    # Podman ping inside a container
    read -p "CONTAINERS_CONF=containers.conf podman top -l capeff"
    echo ""
    CONTAINERS_CONF=containers.conf podman top -l capeff
    echo ""

    # Podman inside a container
    read -p "
Notice NET_RAW as well as AUDIT_WRITE, SYS_CHROOT, and MKNOD capabilies are gone

CONTAINERS_CONF=containers.conf podman run ping ping -c 3 4.2.2.2"
    echo ""
    CONTAINERS_CONF=containers.conf podman run ping ping -c 3 4.2.2.2
    echo ""
    read -p "
Fails because ${bold}NET_RAW${reset} disabled.

"

cat >> containers.conf <<EOF

default_sysctls = [
  "net.ipv4.ping_group_range=0 1000",
]

EOF

    # Podman ping inside a container
    read -p "
Let's add the net.ipv4.ping_group syscall to the containers.conf

cat containers.conf
"
    echo ""
    cat containers.conf
    echo ""

    # Podman inside a container
    read -p "CONTAINERS_CONF=containers.conf podman run ping ping -c 3 4.2.2.2"
    echo ""
    CONTAINERS_CONF=containers.conf podman run ping ping -c 3 4.2.2.2
    echo ""
    read -p "end demo"
    clear
}

userns() {
    # Podman user namespace
    read -p "Podman User Namespace Support"
    echo ""

    read -p "--> sudo podman run --uidmap 0:100000:5000 -d fedora sleep 1000"
    sudo podman run --net=host --uidmap 0:100000:5000 -d fedora sleep 1000
    echo ""

    read -p "--> sudo podman top --latest user huser | grep --color=auto -B 1 100000"
    sudo podman top --latest user huser | grep --color=auto -B 1 100000
    echo ""

    read -p "--> ps -ef | grep -v grep | grep --color=auto 100000"
    ps -ef | grep -v grep | grep --color=auto 100000
    echo ""

    read -p "--> sudo podman run --uidmap 0:200000:5000 -d fedora sleep 1000"
    sudo podman run --net=host --uidmap 0:200000:5000 -d fedora sleep 1000
    echo ""

    read -p "--> sudo podman top --latest user huser | grep --color=auto -B 1 200000"
    sudo podman top --latest user huser | grep --color=auto -B 1 200000
    echo ""

    read -p "--> ps -ef | grep -v grep | grep --color=auto 200000"
    ps -ef | grep -v grep | grep --color=auto 200000
    echo ""

    read -p "--> clear"
    clear
}

setup

ping

seccomp

containers_conf_ping

buildah_image

userns

read -p "End of Demo"
echo "Thank you!"
