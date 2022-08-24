#!/usr/bin/env sh

# podmah.sh demo script.
# This script will demonstrate a lot of the features of podman, concentrating
# on the security features.

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
    sudo cp /usr/share/audit/sample-rules/10-base-config.rules /etc/audit/rules.d/audit.rules
    sudo augenrules --load > /dev/null
    sudo systemctl restart auditd 2> /dev/null
    sudo systemctl restart docker
    clear
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

rootless() {
    # Rootless podman
    read -p "Podman as rootless"
    echo ""

    read -p "--> podman pull alpine"
    podman pull alpine
    echo ""

    read -p "--> podman run --net=host --rm alpine ls"
    podman run --net=host alpine ls
    echo ""

    echo "Show Non Privileged containers"
    read -p "--> podman ps -a"
    podman ps -a
    echo ""

    echo "Show Non Privileged images"
    read -p "--> podman images"
    podman images
    echo ""

    echo "Show Privileged images"
    read -p "--> sudo podman images"
    sudo podman images
    echo ""

    read -p "--> clear"
    clear
}

userns() {
    echo "
The demo will now unshare the usernamespace of a rootless container,
using the 'podman unshare' command.

First outside of the continer, we will cat /etc/subuid, and you should
see your username.  This indicates the UID map that is assigned to you.
When executing podman unshare, it will map your UID to root within the container
and then map the range of UIDS in /etc/subuid starting at UID=1 within your container.
"
    read -p "--> cat /etc/subuid"
    cat /etc/subuid
    echo ""

    echo "


Explore your home directory to see what it looks like while in a user namespace.
'cat /proc/self/uid_map' will show you the user namespace mapping.

Type 'exit' to exit the user namespace and continue running the demo.
"
    read -p "--> podman unshare"
    podman unshare
    echo ""

    read -p "--> clear"
    clear

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

forkexec() {
    # Podman Fork/Exec model
    read -p "Podman Fork/Exec Model"
    echo ""

    read -p "--> cat /proc/self/loginuid"
    cat /proc/self/loginuid
    echo ""
    echo ""

    read -p "--> sudo podman run -ti fedora bash -c \"cat /proc/self/loginuid; echo\""
    sudo podman run -ti fedora bash -c "cat /proc/self/loginuid; echo"
    echo ""

    read -p "--> sudo docker run -ti fedora bash -c \"cat /proc/self/loginuid; echo\""
    sudo docker run -ti fedora bash -c "cat /proc/self/loginuid; echo"
    echo ""

    read -p "--> sudo auditctl -w /etc/shadow"
    sudo auditctl -w /etc/shadow 2>/dev/null
    echo ""

    # Showing how podman keeps track of the person trying to wreak havoc on your system
    read -p "--> sudo podman run --privileged -v /:/host fedora touch /host/etc/shadow"
    sudo podman run --privileged -v /:/host fedora touch /host/etc/shadow
    echo ""

    read -p "--> ausearch -m path -ts recent -i | grep touch | tail -n 1 | grep --color=auto 'auid=[^ ]*'"
    sudo ausearch -m path -ts recent -i | grep touch | tail -n 1 | grep --color=auto 'auid=[^ ]*'
    echo ""

    read -p "--> sudo docker run --privileged -v /:/host fedora touch /host/etc/shadow"
    sudo docker run --privileged -v /:/host fedora touch /host/etc/shadow
    echo ""

    read -p "--> ausearch -m path -ts recent -i | grep touch | tail -n 1 | grep --color=auto 'auid=[^ ]*'"
    sudo ausearch -m path -ts recent -i | grep touch | tail -n 1 |grep --color=auto 'auid=[^ ]*'
    echo ""

    read -p "--> clear"
    clear
}

top() {
    # Podman top commands
    read -p "Podman top features"
    echo ""

    read -p "--> sudo podman run -d fedora sleep 1000"
    sudo podman run -d fedora sleep 1000
    echo ""

    read -p "--> sudo podman top --latest pid hpid"
    sudo podman top --latest pid hpid
    echo ""

    read -p "--> sudo podman top --latest label"
    sudo podman top --latest label
    echo ""

    read -p "--> sudo podman top --latest seccomp"
    sudo podman top --latest seccomp
    echo ""

    read -p "--> sudo podman top --latest capeff"
    sudo podman top --latest capeff
    echo ""

    read -p "--> clear"
    clear
}

pods() {
    sudo podman kill -a
    sudo podman rm -a -f
    clear

    read -p "--> sudo podman pod list"
    sudo podman pod list
    echo ""

    read -p "--> sudo podman pod --name podtest create"
    sudo podman pod create --name podtest
    echo ""

    read -p "--> sudo podman create --pod podtest fedora sleep 600"
    sudo podman create --pod podtest fedora sleep 600
    echo ""

    read -p "--> sudo podman create --pod podtest fedora sleep 600"
    sudo podman create --pod podtest fedora sleep 600
    echo ""

    echo "
Notice that you have no containers running.
"
    read -p "--> sudo podman ps"
    sudo podman ps
    echo ""

    read -p "--> sudo podman pod start podtest"
    sudo podman pod start podtest
    echo ""

    echo "
Notice that the \"podman pod start podtest\" command started both containers.
"
    read -p "--> sudo podman ps"
    sudo podman ps
    echo ""

    read -p "--> sudo podman pod stop podtest"
    sudo podman pod kill --signal KILL podtest
    echo ""

    echo "
Notice that the \"podman pod stop podtest\" command stopped both containers.
"
    read -p "--> sudo podman ps"
    sudo podman ps
    echo ""

    echo "
Remove the pod and all of the containers
"
    read -p "--> sudo podman pod rm --force podtest"
    sudo podman pod rm --force podtest
    echo ""
    clear

    echo "
Pod should no longer exist
"
    read -p "--> sudo podman pod list"
    sudo podman pod list
    echo ""
}

build() {
    echo ""
    # Already built an image with buildah installed in it
    # and made buildah the entrypoint

    sudo mkdir -p /var/lib/mycontainer
    mkdir -p $PWD/myvol
    cat >$PWD/myvol/Dockerfile <<_EOF
FROM alpine
ENV foo=bar
LABEL colour=blue
_EOF

    read -p "--> cat Dockerfile"
    cat $PWD/myvol/Dockerfile
    echo ""
    echo ""
    read -p "--> sudo podman run -v \$PWD/myvol:/myvol:Z -v /var/lib/mycontainer:/var/lib/containers:Z quay.io/buildah/stable buildah build -t myimage --isolation chroot /myvol"

    sudo podman run --net=host --device /dev/fuse -v $PWD/myvol:/myvol:Z -v /var/lib/mycontainer:/var/lib/containers:Z quay.io/buildah/stable buildah build -t myimage --isolation chroot /myvol
    echo ""

    read -p "--> sudo podman run --device /dev/fuse -v /var/lib/mycontainer:/var/lib/containers:Z quay.io/buildah/stable buildah images"
    sudo podman run --net=host -v /var/lib/mycontainer:/var/lib/containers:Z quay.io/buildah/stable buildah images
    echo ""

    read -p "--> sudo podman run -v /var/lib/mycontainer:/var/lib/containers:Z	quay.io/buildah/stable buildah rmi --force --all"
    sudo podman run --net=host -v /var/lib/mycontainer:/var/lib/containers:Z quay.io/buildah/stable buildah rmi -f --all
    echo ""

    read -p "--> cleanup"
    echo "podman rm -a -f"
    sudo podman rm -a -f
    echo ""

    read -p "--> clear"
    clear
}

intro() {
    read -p "Podman Demos!"
    echo ""
}

setup

intro

version

build

rootless

userns

forkexec

top

pods

read -p "End of Demo"
echo "Thank you!"
