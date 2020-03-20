#!/bin/sh

bold=$(tput bold)
blue=$(tput setaf 6)
yellow=$(tput setaf 11)
reset=$(tput sgr0)

# podmah.sh demo script.

read -p "${bold}${yellow}This script will demonstrate new security features of podman${reset}"
echo ""
clear

setup() {
    rpm -q podman audit oci-seccomp-bpf-hook perl-JSON-PP >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the podman, oci-seccomp-bpf-hook, perl-JSON-PP, and audit packages be installed
	exit 1
    fi
    augenrules --load > /dev/null
    systemctl restart auditd 2> /dev/null
    cat > /tmp/Containerfile <<EOF
FROM ubi8
RUN  dnf -y install iputils
EOF
    podman build -t ping -f /tmp/Containerfile /tmp
    cat > /tmp/Fedorafile <<EOF
FROM fedora
RUN dnf install -y nc
EOF
    podman build -t myfedora -f /tmp/Fedorafile /tmp
    cat > /tmp/Capfile <<EOF
FROM fedora
LABEL "io.containers.capabilities=SETUID,SETGID"
EOF
    podman build -t fedoracap -f /tmp/Capfile /tmp
    cat > /tmp/InvalidCapfile <<EOF
FROM fedora
LABEL "io.containers.capabilities=NET_ADMIN,SYS_ADMIN"
EOF
    podman build -t fedorainvalidcap -f /tmp/InvalidCapfile /tmp
    clear
}

ping() {
    read -p "
${blue}${bold}Dropping capabilities prevents ${yellow}ping${reset}${blue}${bold} command from working.

This demonstration show how to drop the NET_RAW Linux capability, and
then how to set a syscall inside of the container, which allows the ping
command to work again.${reset}
"
    # Podman ping inside a container
    read -p "${bold}--> podman run ping ping -c 3 4.2.2.2${reset}"
    echo ""
    podman run ping ping -c 3 4.2.2.2
    echo ""

    # Podman inside a container
    read -p "${bold}--> podman run ${yellow}--cap-drop NET_RAW${reset}${bold} ping ping -c 3 4.2.2.2${reset}"
    echo ""
    podman run --cap-drop NET_RAW ping ping -c 3 4.2.2.2
    echo ""
    read -p "
${blue}${bold}Fails because ${yellow}NET_RAW${reset}${blue}${bold} disabled.${reset}"

    # Podman inside a container
    read -p "
${blue}${bold}Execute same container with --sysctl 'net.ipv4.ping_group_range=0 1000' enabled${reset}"

    read -p "${bold}--> podman run -sysctl --cap-drop NET_RAW ${yellow}--sysctl 'net.ipv4.ping_group_range=0 1000'${reset}${bold} ping ping -c 3 4.2.2.2${reset}"
    echo ""
    podman run -ti --cap-drop NET_RAW --sysctl 'net.ipv4.ping_group_range=0 1000' ping ping -c 3 4.2.2.2
    echo ""
    read -p "${bold}--> clear${reset}"
    clear
}

capabilities_in_image() {
    read -p "${blue}${bold}Let image developer select the capabilities they want in the image by setting a label${reset}"
    read -p "${bold}--> cat /tmp/Dockerfile.capabilities${reset}"
    cat /tmp/Capfile
    echo ""
    read -p "${bold}--> podman run --name capctr -d fedoracap sleep 1000${reset}"
    podman run --name capctr -d fedoracap sleep 1000
    echo ""
    read -p "${bold}--> podman top capctr capeff${reset}"
    podman top capctr capeff
    echo ""
    read -p "${bold}--> podman run --name defctr -d fedora sleep 1000${reset}"
    podman run --name defctr -d fedora sleep 1000
    echo ""
    read -p "${bold}--> podman top defctr capeff${reset}"
    podman top defctr capeff
    echo ""
    read -p "${bold}--> cat /tmp/Dockerfile.InvalidCapabilities${reset}"
    cat /tmp/InvalidCapfile
    echo ""
    read -p "${bold}--> podman run --name invalidcapctr -d fedorainvalidcap sleep 1000${reset}"
    podman run --name invalidcapctr -d fedorainvalidcap sleep 1000
    echo ""
    read -p "${bold}--> podman top invalidcapctr capeff${reset}"
    podman top invalidcapctr capeff
    echo ""
    read -p "${bold}--> podman run -d --cap-add SYS_ADMIN --cap-add NET_ADMIN fedorainvalidcap sleep 1000${reset}"
    podman run -d --cap-add SYS_ADMIN --cap-add NET_ADMIN fedorainvalidcap sleep 1000
    echo ""
    read -p "${bold}--> podman top -l capeff${reset}"
    podman top -l capeff
    echo ""
    read -p "${bold}--> cleanup${reset}"
    podman rm -af
    read -p "${bold}--> clear${reset}"
    clear
}


udica_demo() {
    read -p "${bold}${blue}Podman run with volumes using udica${reset}"
    # check /home, /var/spool, and the network nc -lvp (port)
    read -p "${bold}--> podman run --rm -v /home:/home:ro -v /var/spool:/var/spool:rw -it myfedora bash${reset}"
    echo ""
    podman run -v /home:/home:ro -v /var/spool:/var/spool:rw -it myfedora bash
    echo ""
    read -p "${bold}${blue}Use udica to generate a custom policy for this container${reset}"
    echo ""
    read -p "${bold}--> podman run --name myctr -v /home:/home:ro -v /var/spool:/var/spool:rw -d myfedora sleep 1000${reset}"
    echo ""
    podman run --name myctr -v /home:/home:ro -v /var/spool:/var/spool:rw -d myfedora sleep 1000
    echo ""
    read -p "${bold}--> podman inspect myctr | udica my_container${reset}"
    echo ""
    podman inspect myctr | udica my_container
    echo ""
    read -p "${bold}--> semodule -i my_container.cil /usr/share/udica/templates/{base_container.cil,net_container.cil,home_container.cil}${reset}"
    semodule -i my_container.cil /usr/share/udica/templates/{base_container.cil,net_container.cil,home_container.cil}
    echo ""
    read -p "${blue}${bold}Let's restart the container${reset}"
    echo ""
    read -p "${bold}--> podman run --name udica_ctr --security-opt label=type:my_container.process -v /home:/home:ro -v /var/spool:/var/spool:rw -d myfedora sleep 1000${reset}"
    echo ""
    podman run --name udica_ctr --security-opt label=type:my_container.process -v /home:/home:ro -v /var/spool:/var/spool:rw -d myfedora sleep 1000
    echo ""
    read -p "${bold}--> ps -efZ | grep my_container.process${reset}"
    ps -efZ | grep my_container.process
    echo ""
    read -p "${bold}--> podman exec -it udica_ctr bash${reset}"
    podman exec -it udica_ctr bash
    echo ""
    read -p "${bold}--> cleanup${reset}"
    podman rm -af 2> /dev/null
    echo ""
    read -p "${bold}--> clear${reset}"
    clear
}

syscalls() {
    out=$(awk '/SYSCALL/{print $NF}' /var/log/audit/audit.log | grep SYSCALL | cut -f2 -d = | sort -u)
    echo "
"
    for i in $out; do echo -n \"$i\",; done
    echo "
"
    read -p ""
}

seccomp() {
    # Podman Generate Seccomp Rules
    read -p "${blue}${bold}
Podman Generate Seccomp Rules

This demonstration with use an OCI Hook to fire up a BPF Program to trace
all sycalls generated from a container.

We will then use the generated seccomp file to lock down the container, only
allowing the generated syscalls, rather then the system default.${reset}
"
    echo ""

    read -p "${bold}--> less /usr/share/containers/oci/hooks.d/oci-seccomp-bpf-hook.json${reset}"
    less /usr/share/containers/oci/hooks.d/oci-seccomp-bpf-hook.json
    echo ""
    echo ""

    read -p "${bold}--> podman run ${yellow}--annotation io.containers.trace-syscall=of:/tmp/myseccomp.json${reset}${bold} fedora ${yellow}ls /${reset}"
    podman run --rm --annotation io.containers.trace-syscall=of:/tmp/myseccomp.json fedora ls /
    echo ""

    read -p "${bold}--> cat /tmp/myseccomp.json | json_pp${reset}"
    cat /tmp/myseccomp.json | json_pp > /tmp/myseccomp.pp
    less /tmp/myseccomp.pp
    echo ""
    clear
    read -p "${bold}--> podman run ${yellow}--security-opt seccomp=/tmp/myseccomp.json${reset}${bold} fedora ${yellow}ls /${reset}"
    podman run --rm --security-opt seccomp=/tmp/myseccomp.json fedora ls /
    echo ""
    read -p "${bold}--> clear${reset}"
    clear

    read -p "${bold}--> podman run --security-opt seccomp=/tmp/myseccomp.json fedora ${yellow}ls -l /${reset}"
    podman run --rm --security-opt seccomp=/tmp/myseccomp.json fedora ls -l /
    echo ""

    read -p "${bold}--> grep --color SYSCALL=.* /var/log/audit/audit.log${reset}"
    grep --color SYSCALL=.* /var/log/audit/audit.log
    echo ""

    syscalls

    read -p "${bold}--> podman run --annotation io.containers.trace-syscall=\"if:/tmp/myseccomp.json;of:/tmp/myseccomp2.json\" fedora ls -l / > /dev/null${reset}"
    podman run --rm --annotation io.containers.trace-syscall="if:/tmp/myseccomp.json;of:/tmp/myseccomp2.json" fedora ls -l /
    echo ""

    read -p "${bold}--> podman run --security-opt seccomp=/tmp/myseccomp2.json fedora ls -l /${reset}"
    podman run --rm --security-opt seccomp=/tmp/myseccomp2.json fedora ls -l /
    echo ""

    read -p "${bold}--> diff -u /tmp/myseccomp.json /tmp/myseccomp2.json${reset}"
    cat /tmp/myseccomp2.json | json_pp > /tmp/myseccomp2.pp
    diff -u /tmp/myseccomp.pp /tmp/myseccomp2.pp | less
    read -p "${bold}--> clear${reset}"
    clear
}


containers_conf_ping() {
    read -p "${blue}${bold}
This demonstration will show how you can specify the default linux capabilities
for all containers on your system.

Then of the demonstration will show ping still running without NET_RAW
Capability, since containers_conf will automatically set the sycall.
${reset}"
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
    read -p "${bold}--> podman run -d fedora sleep 6000${reset}"
    echo ""
    podman run -d fedora sleep 6000
    echo ""

    # Podman ping inside a container
    read -p "${bold}--> podman top -l capeff${reset}"
    echo ""
    podman top -l capeff |  grep --color=auto -B 1 NET_RAW
    echo ""

    # Podman ping inside a container
    read -p "${bold}--> cat containers.conf${reset}"
    echo ""
    cat containers.conf
    echo ""

    # Podman ping inside a container
    read -p "${bold}--> CONTAINERS_CONF=containers.conf podman run -d fedora sleep 6000${reset}"
    echo ""
    CONTAINERS_CONF=containers.conf podman run -d fedora sleep 6000
    echo ""

    # Podman ping inside a container
    read -p "${bold}--> CONTAINERS_CONF=containers.conf podman top -l capeff${reset}"
    echo ""
    CONTAINERS_CONF=containers.conf podman top -l capeff
    echo ""

    # Podman inside a container
    read -p "${blue}${bold}
Notice NET_RAW as well as AUDIT_WRITE, SYS_CHROOT, and MKNOD capabilies are gone${reset}"

    read -p "${bold}--> CONTAINERS_CONF=containers.conf podman run ping ping -c 3 4.2.2.2${reset}"
    echo ""
    CONTAINERS_CONF=containers.conf podman run ping ping -c 3 4.2.2.2
    echo ""
    read -p "${blue}${bold}
Fails because ${yellow}NET_RAW${reset}${blue}${bold} disabled${reset}.

"

cat >> containers.conf <<EOF

default_sysctls = [
  "net.ipv4.ping_group_range=0 1000",
]

EOF

    # Podman ping inside a container
    read -p "${blue}${bold}
Let's add the ${yellow}net.ipv4.ping_group syscall${reset}${blue}${bold} to the containers.conf${reset}"

    read -p "${bold}--> cat containers.conf${reset}"
    echo ""
    cat containers.conf
    echo ""

    # Podman inside a container
    read -p "${bold}--> CONTAINERS_CONF=containers.conf podman run ping ping -c 3 4.2.2.2${reset}"
    echo ""
    CONTAINERS_CONF=containers.conf podman run ping ping -c 3 4.2.2.2
    echo ""
    read -p "${bold}--> clear${reset}"
    clear
}
CONTAINERS_CONF=containers.conf
userns() {
    # Note, this is still a WIP and has not yet been merged into podman master
    # Podman user namespace
    read -p "${blue}${bold}Podman User Namespace Support${reset}"
    echo ""

    read -p "${bold}--> podman run --uidmap 0:100000:5000 -d fedora sleep 1000${reset}"
    podman run --net=host --uidmap 0:100000:5000 -d fedora sleep 1000
    echo ""

    read -p "${bold}--> podman top --latest user huser | grep --color=auto -B 1 100000${reset}"
    podman top --latest user huser | grep --color=auto -B 1 100000
    echo ""

    read -p "${bold}--> ps -ef | grep -v grep | grep --color=auto 100000${reset}"
    ps -ef | grep -v grep | grep --color=auto 100000
    echo ""

    read -p "${bold}--> podman run --uidmap 0:200000:5000 -d fedora sleep 1000${reset}"
    podman run --net=host --uidmap 0:200000:5000 -d fedora sleep 1000
    echo ""

    read -p "${bold}--> podman top --latest user huser | grep --color=auto -B 1 200000${reset}"
    podman top --latest user huser | grep --color=auto -B 1 200000
    echo ""

    read -p "${bold}--> ps -ef | grep -v grep | grep --color=auto 200000${reset}"
    ps -ef | grep -v grep | grep --color=auto 200000
    echo ""

    read -p "${bold}--> clear${reset}"
    clear

    read -p "${blue}${bold}Podman User Namespace Support Using --userns=auto${reset}"
    echo ""

    read -p "${bold}--> podman run --userns=auto -d fedora sleep 1000${reset}"
    ./bin/podman run --userns=auto -d fedora sleep 1000
    echo ""

    read -p "${bold}--> podman top --latest user huser${reset}"
    ./bin/podman top --latest user huser
    echo ""

    read -p "${bold}--> podman run --userns=auto -d fedora sleep 1000${reset}"
    ./bin/podman run --userns=auto -d fedora sleep 1000
    echo ""

    read -p "${bold}--> podman top --latest user huser${reset}"
    ./bin/podman top --latest user huser
    echo ""

    read -p "${bold}--> podman run --userns=auto:size=5000 -d fedora sleep 1000${reset}"
    ./bin/podman run --userns=auto:size=5000 -d fedora sleep 1000
    echo ""

    read -p "${bold}--> podman top --latest user huser${reset}"
    ./bin/podman top --latest user huser
    echo ""

    read -p "${bold}--> podman exec --latest cat /proc/self/uid_map${reset}"
    ./bin/podman exec --latest cat /proc/self/uid_map
    echo ""

    read -p "${bold}--> cleanup${reset}"
    ./bin/podman rm -af
    echo ""

    read -p "${bold}--> clear${reset}"
    clear
}

setup
ping
capabilities_in_image
seccomp
udica_demo
userns
containers_conf_ping

read -p "${yellow}${bold}End of Demo"
echo "Thank you!${reset}"
