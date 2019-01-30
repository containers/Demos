#!/bin/sh

# security_demo.sh demo script.
# This script will demonstrate security features of buildah,podman,skopeo and cri-o

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

POD=
# only remove images if they were added by this script
UBUNTU_RMI=false
ALPINE_RMI=false
FEDORA_DOCKER_RMI=false
FEDORA_PODMAN_RMI=false
BUILDAH_CTR_RMI=false
cleanup() {
    echo_bright "--> cleanup"
    echo ""
    sudo rm -f /etc/audit/rules.d/audit-demo.rules
    sudo augenrules --load > /dev/null
    sudo systemctl restart auditd 2> /dev/null
    sudo rm -f a_file_owned_by_root
    rm -rf "$PWD"/myvol
    if $BUILDAH_CTR_RMI; then
        sudo podman rmi buildah-ctr:latest
    fi
    if $FEDORA_DOCKER_RMI; then
        sudo docker rmi fedora:latest
    fi
    if $FEDORA_PODMAN_RMI; then
        sudo podman rmi fedora:latest
    fi
    if $UBUNTU_RMI; then
        sudo docker rmi ubuntu:latest
    fi
    if $ALPINE_RMI; then
        podman rmi alpine:latest
    fi
    if sudo podman images | grep ubuntu | grep demo; then
        sudo podman rmi ubuntu:demo
    fi
    if [ ! -z $POD ]; then
        sudo crictl stopp $POD
        sudo crictl rmp $POD
    fi
    sudo podman stop -t 0 --all 2> /dev/null
    sudo podman rm -f --all 2> /dev/null
    sudo systemctl restart docker
}

trap cleanup EXIT
# Initial setup
setup() {
    if ! rpm -q podman buildah audit >/dev/null; then
	echo "$0" requires the podman, buildah and audit packages be installed
	exit 1
    fi
    if ! command -v docker > /dev/null; then
	echo "$0" requires the docker package be installed
	exit 1
    fi
    sudo cp /usr/share/doc/audit/rules/10-base-config.rules /etc/audit/rules.d/audit-demo.rules
    sudo augenrules --load > /dev/null
    sudo systemctl restart auditd 2> /dev/null
    if ! sudo docker images | grep ubuntu | grep latest; then
	UBUNTU_RMI=true
        sudo docker pull ubuntu:latest
    fi
    if ! sudo docker images | grep fedora | grep latest; then
	FEDORA_DOCKER_RMI=true
	sudo docker pull fedora:latest
    fi
    if ! sudo podman images | grep fedora | grep latest; then
	FEDORA_PODMAN_RMI=true
	sudo podman pull fedora:latest
    fi
    sudo touch a_file_owned_by_root
    sudo chmod 0600 a_file_owned_by_root
    clear
}

buildah_image() {
    if ! sudo podman images  | grep -q -w buildah-ctr; then
	BUILDAH_CTR_RMI=true
	sudo podman pull quay.io/sallyom/buildah-ctr
    fi
}

intro() {
    read_yellow "Demos!  Buildah, Podman, Skopeo, CRI-O Security"
    echo ""
    clear
}

buildah_minimal_image() {
  # Buildah from scratch - minimal images
  read_yellow "Buildah from scratch - building minimal images"
  echo ""

  read_bright "--> ctr=\$(sudo buildah from scratch)"
  ctr=$(sudo buildah from scratch)
  echo "$ctr"
  echo ""

  read_bright "--> mnt=\$(sudo buildah mount \$ctr)"
  mnt=$(sudo buildah mount "$ctr")
  echo "$mnt"
  echo ""

  echo_bright "--> sudo dnf install -y --installroot=\$mnt busybox --releasever=29 --disablerepo=* --enablerepo=fedora"
  sudo dnf install -y --installroot="$mnt" busybox --releasever=29 --disablerepo=* --enablerepo=fedora 2> /dev/null
  echo ""

  read_bright "--> sudo dnf clean all --installroot=\$mnt"
  echo ""
  sudo dnf clean all --installroot="$mnt" 2> /dev/null
  echo ""

  read_bright "--> sudo buildah unmount \$ctr"
  sudo buildah unmount "$ctr"
  echo ""

  read_bright "--> sudo buildah commit --rm \$ctr minimal-image"
  sudo buildah commit --rm "$ctr" minimal-image
  echo ""

  read_bright "--> sudo podman run --rm minimal-image ping"
  sudo podman run --rm minimal-image ping
  echo ""

  read_bright "--> sudo podman run --rm minimal-image python"
  sudo podman run --rm minimal-image python
  echo ""

  read_bright "--> sudo podman run --rm minimal-image busybox"
  sudo podman run --rm minimal-image busybox
  echo ""

  read_bright "--> clear"
  clear
}

buildah_in_container() {
    # Buildah inside a container
    read_yellow "Buildah inside a container"
    echo ""
    read_bright "--> cat Dockerfile.buildah (built previously)"
    cat <<_EOF
FROM fedora
RUN dnf -y install buildah; dnf -y clean all
ENTRYPOINT ["/usr/bin/buildah"]
WORKDIR /root
_EOF
    echo ""
    echo ""
    sudo mkdir -p /var/lib/mycontainer
    mkdir -p "$PWD"/myvol
    cat >"$PWD"/myvol/Dockerfile <<_EOF
FROM alpine
ENV foo=bar
LABEL colour=bright
_EOF

    read_bright "--> cat Dockerfile (used inside buildah-ctr)"
    cat "$PWD"/myvol/Dockerfile
    echo ""
    echo ""
    read_bright "--> sudo podman run --rm -v \$PWD/myvol:/myvol:Z -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs bud -t myimage --isolation chroot /myvol"
    sudo podman run --rm --net=host -v "$PWD"/myvol:/myvol:Z -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs bud -t myimage --isolation chroot /myvol
    echo ""

    read_bright "--> sudo podman run --rm -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs images"
    sudo podman run --rm --net=host -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs images
    echo ""

    read_bright "--> sudo podman run --rm -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs rmi --force --all"
    sudo podman run --rm --net=host -v /var/lib/mycontainer:/var/lib/containers:Z buildah-ctr --storage-driver vfs rmi -f --all
    echo ""

    read_bright "--> clear"
    clear
}

podman_rootless() {
    # Rootless podman
    read_yellow "Podman as rootless"
    echo ""

    read_bright "--> podman images | grep alpine | grep latest"
    if ! podman images | grep alpine | grep latest; then
        read_bright "--> podman pull alpine:latest"
        ALPINE_RMI=true
        podman pull alpine:latest
    fi
    echo ""

    read_yellow "non-privileged images"
    read_bright "--> podman images"
    podman images
    echo ""

    read_yellow "privileged images"
    read_bright "--> sudo podman images"
    sudo podman images
    echo ""

    read_bright "--> podman run --rm alpine:latest id && echo On the host I am not root && id"
    podman run --rm --net=host --rm alpine:latest id && echo On the host I am not root && id
    echo ""

    read_bright "--> clear"
    clear
}

podman_userns() {
    echo_bright "
The demo will now unshare the usernamespace of a rootless container,
using the 'buildah unshare' command.

First outside of the container, we will cat /etc/subuid, and you should
see your username.  This indicates the UID map that is assigned to you.
When executing buildah unshare, it will map your UID to root within the container
and then map the range of UIDS in /etc/subuid starting at UID=1 within your container.
"
    echo ""
    read_bright "--> cat /etc/subuid"
    cat /etc/subuid
    echo ""

    echo_bright "


Explore your home directory to see what it looks like while in a user namespace.
'cat /proc/self/uid_map' will show you the user namespace mapping.
'ls -al' will show a file owned by root on the host system, by nfsnobody in the userns.

Type 'exit' to exit the user namespace and continue running the demo.
"
    read_bright "--> ls -al (on the host)"
    ls -al
    echo ""
    read_bright "--> buildah unshare"
    buildah unshare
    echo ""

    read_bright "--> clear"
    clear

    # Podman user namespace
    read_yellow "Podman User Namespace Support"
    echo ""

    read_bright "--> sudo podman run --uidmap 0:100000:5000 -d fedora:latest sleep 1000"
    sudo podman run --net=host --uidmap 0:100000:5000 -d fedora:latest sleep 1000
    echo ""

    read_bright "--> sudo podman top --latest user huser | grep --color=auto -B 1 100000"
    sudo podman top --latest user huser | grep --color=auto -B 1 100000
    echo ""

    read_bright "--> ps -ef | grep -v grep | grep --color=auto 100000"
    ps -ef | grep -v grep | grep --color=auto 100000
    echo ""
    sudo podman stop -l -t 0 2> /dev/null
    sudo podman rm -f -l 2> /dev/null

    read_bright "--> sudo podman run --uidmap 0:200000:5000 -d fedora:latest sleep 1000"
    sudo podman run --net=host --uidmap 0:200000:5000 -d fedora:latest sleep 1000
    echo ""

    read_bright "--> sudo podman top --latest user huser | grep --color=auto -B 1 200000"
    sudo podman top --latest user huser | grep --color=auto -B 1 200000
    echo ""

    read_bright "--> ps -ef | grep -v grep | grep --color=auto 200000"
    ps -ef | grep -v grep | grep --color=auto 200000
    echo ""

    read_bright "--> cleanup"
    sudo podman stop -t 0 --all 2> /dev/null
    sudo podman rm -f -all 2> /dev/null
    echo ""

    read_bright "--> clear"
    clear
}

podman_fork_exec() {
    # Podman Fork/Exec model
    read_yellow "Podman Fork/Exec Model"
    echo ""

    read_bright "--> cat /proc/self/loginuid"
    cat /proc/self/loginuid
    echo ""
    echo ""

    read_bright "--> sudo podman run -ti --rm fedora:latest bash -c \"cat /proc/self/loginuid; echo\""
    sudo podman run -ti --rm fedora:latest bash -c "cat /proc/self/loginuid; echo"
    echo ""

    read_bright "--> sudo docker run -ti --rm fedora:latest bash -c \"cat /proc/self/loginuid; echo\""
    sudo docker run -ti --rm fedora:latest bash -c "cat /proc/self/loginuid; echo"
    echo ""

    # Showing how podman keeps track of the person trying to wreak havoc on your system
    read_bright "--> sudo auditctl -w /etc/shadow"
    sudo auditctl -w /etc/shadow 2>/dev/null
    echo ""

    read_bright "--> sudo podman run --rm --privileged -v /:/host fedora:latest touch /host/etc/shadow"
    sudo podman run --privileged --rm -v /:/host fedora:latest touch /host/etc/shadow
    echo ""

    read_bright "--> ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'"
    sudo ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'
    echo ""

    read_bright "--> sudo docker run --rm --privileged -v /:/host fedora:latest touch /host/etc/shadow"
    sudo docker run --privileged --rm -v /:/host fedora:latest touch /host/etc/shadow
    echo ""

    read_bright "--> ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'"
    sudo ausearch -m path -ts recent -i | grep touch | grep --color=auto 'auid=[^ ]*'
    echo ""

    read_bright "--> clear"
    clear
}

podman_top() {
    # Podman top commands
    read_yellow "Podman top features"
    echo ""

    read_bright "--> sudo podman run -d fedora:latest sleep 1000"
    sudo podman run -d fedora:latest sleep 1000
    echo ""

    read_bright "--> sudo podman top --latest pid hpid"
    sudo podman top --latest pid hpid
    echo ""

    read_bright "--> sudo podman top --latest label"
    sudo podman top --latest label
    echo ""
    read_bright "--> sudo podman top --latest seccomp"
    sudo podman top --latest seccomp
    echo ""

    read_bright "--> sudo podman top --latest capeff"
    sudo podman top --latest capeff
    echo ""

    read_bright "--> cleanup"
    sudo podman stop -t 0 --all 2> /dev/null
    sudo podman rm -f --all 2> /dev/null
    echo ""

    read_bright "--> clear"
    clear
}

skopeo_inspect() {
    # Skopeo inspect a remote image
    read_yellow "Inspect a remote image using skopeo"
    echo ""

    read_bright "--> skopeo"
    skopeo
    echo ""

    read_bright "--> skopeo inspect docker://docker.io/fedora"
    skopeo inspect docker://docker.io/fedora
    echo ""

    read_bright "--> clear"
    clear
}

skopeo_cp_from_docker_to_podman() {
    read_yellow "Copy images from docker storage to podman storage"
    echo ""

    read_bright "--> sudo podman images"
    sudo podman images
    echo ""

    read_bright "--> sudo docker images"
    sudo docker images
    echo ""

    read_bright "--> sudo skopeo copy docker-daemon:ubuntu:latest containers-storage:localhost/ubuntu:demo"
    sudo skopeo copy docker-daemon:ubuntu:latest containers-storage:localhost/ubuntu:demo 2> /dev/null
    echo ""

    read_bright "--> sudo podman images"
    sudo podman images
    echo ""

    read_bright "--> clear"
    clear
}

crio_read_only() {
    # CRI-O read-only mode
    read_yellow "CRI-O read-only mode"
    echo ""

    read_bright "--> sudo grep read_only /etc/crio/crio.conf"
    sudo grep read_only /etc/crio/crio.conf
    echo ""

    read_bright "--> sudo systemctl restart crio"
    sudo systemctl restart crio
    echo ""

    read_bright "--> POD=\$(sudo crictl runp sandbox_config.json)"
    POD=$(sudo crictl runp sandbox_config.json)
    echo "$POD"
    echo ""

    read_bright "--> CTR=\$(sudo crictl create \$POD container_demo.json sandbox_config.json)"
    CTR=$(sudo crictl create "$POD" container_demo.json sandbox_config.json)
    echo "$CTR"
    echo ""

    read_bright "--> sudo crictl start \$CTR"
    sudo crictl start "$CTR"
    echo ""

    read_bright "--> sudo crictl exec --sync \$CTR dnf install buildah"
    sudo crictl exec --sync "$CTR" dnf install buildah
    echo ""

    read_bright "--> cleanup"
    sudo crictl stopp "$POD" 2> /dev/null
    sudo crictl rmp "$POD" 2> /dev/null
    echo ""

    read_bright "--> clear"
    clear
}

crio_modify_caps() {
    # Modifying capabilities in CRI-O
    read_yellow "Modifying capabilities in CRI-O"
    echo ""

    read_bright "--> sudo vim /etc/crio/crio.conf"
    sudo vim /etc/crio/crio.conf
    #sudo emacs -nw /etc/crio/crio.conf
    echo ""

    read_bright "--> sudo systemctl restart crio"
    sudo systemctl restart crio
    echo ""

    read_bright "--> POD=\$(sudo crictl runp sandbox_config.json)"
    POD=$(sudo crictl runp sandbox_config.json)
    echo "$POD"
    echo ""

    read_bright "--> CTR=\$(sudo crictl create \$POD container_demo.json sandbox_config.json)"
    CTR=$(sudo crictl create "$POD" container_demo.json sandbox_config.json)
    echo "$CTR"
    echo ""

    read_bright "--> sudo crictl start \$CTR"
    sudo crictl start "$CTR"
    echo ""

    read_bright "--> sudo crictl exec -i -t \$CTR capsh --print"
    sudo crictl exec -i -t "$CTR" capsh --print
    echo ""

    read_bright "--> sudo cat /run/containers/storage/overlay-containers/\$POD/userdata/config.json | grep -A 50 'ociVersion'"
    sudo cat /run/containers/storage/overlay-containers/"$POD"/userdata/config.json | grep -A 50 'ociVersion'
    echo ""

    read_bright "--> cleanup"
    sudo crictl stopp "$POD"
    sudo crictl rmp "$POD"
    echo ""

    read_bright "--> clear"
    clear
}

setup
buildah_image
intro
buildah_minimal_image
buildah_in_container
podman_rootless
podman_userns
podman_fork_exec
podman_top
skopeo_inspect
skopeo_cp_from_docker_to_podman
crio_read_only
crio_modify_caps

read_yellow "End of Demo"
echo_bright "Thank you!"
