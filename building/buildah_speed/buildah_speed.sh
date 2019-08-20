#!/bin/sh

# buildah_speed.sh demo script.
# This script will demonstrate at an speed
# for Buildah command running inside of a container
# the Podman packages must be installed.


# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
cyan=$(tput setaf 6)
reset=$(tput sgr0)
export SLOWEST=/var/lib/buildah_slowest
export MEDIUM=/var/lib/buildah_medium
# There is no FASTEST, since we use the host storage

read_color() {
    read -p "${bold}$1${reset}"
}

echo_color() {
    echo "${cyan}$1${reset}"
}

setup() {
    rpm -q podman >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the podman package to be installed
	exit 1
    fi
    rpm -q buildah >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the buildah package to be installed
	exit 1
    fi
    echo_color "Setting up Demo"
    sudo dnf -y update --downloadonly 2>/dev/null
    for image in fedora ubi8 quay.io/buildah/stable quay.io/buildah/stable quay.io/buildah/upstream; do sudo podman pull -q $image; done 2>/dev/null
    clear
}

intro() {
    read -p "Buildah Speed Demos!"
    echo
}

version() {
    # Buildah version inside a container
    echo_color "Check the Buildah version"
    echo
    read_color "buildah version"
    echo
    sudo buildah version
    echo
    sudo podman run quay.io/buildah/stable buildah version
    echo

    # Buildah info inside a container
    echo
    echo_color "Check the Buildah info"
    echo
    read_color "buildah info"
    echo
    sudo podman run quay.io/buildah/stable buildah info

    echo
    read -p "Enter to continue"
    clear
}

buildah_slowest() {
    echo
    echo_color "
In this example, we are not leaking any information from the host into the
container. The container is fully locked down, and could potentially be run
with separated use namespace. Meaning the build would not be happening as root.

But this is the slowest way to build containers, since the container starts with
no containers/storage, and needs to pull down all image content used in the
build.

Pull an ubi8 image into non shared containers/storage.
"
    echo
    sudo rm -rf $SLOWEST
    sudo mkdir -p $SLOWEST
    sudo chcon -t container_file_t $SLOWEST
    read_color "    sudo podman run -v $SLOWEST:/var/lib/containers:Z quay.io/buildah/stable buildah pull ubi8"
    sudo /bin/time -o /tmp/buildah_slowest.txt --format "%e" podman run -v $SLOWEST:/var/lib/containers:Z quay.io/buildah/stable buildah pull ubi8
    echo_color "
    Completed in $(cat /tmp/buildah_slowest.txt) seconds
"

    echo
    read -p "Enter to continue"
    clear
}

buildah_fastest() {
    echo
    echo_color "
In this example, we are going to mount in the containers/storage read/write from
the host into the containers as an additional store at /var/lib/containers.

Note we have to disable SELinux separation to make this work, since SELinux
would block this access.  This gives you the best speed, since the host will see
your built images instantly.  But least security since the container can write
to the hosts containers/storage.

Pull an ubi8 image into shared read/write containers/storage.
"
    echo
    read_color "    sudo podman run --security-opt label=disable -v /var/lib/containers:/var/lib/containers quay.io/buildah/stable buildah pull ubi8"
    sudo /bin/time -o /tmp/buildah_fastest.txt --format "%e" podman run --security-opt label=disable -v /var/lib/containers:/var/lib/containers quay.io/buildah/stable buildah pull ubi8
    echo_color "
    Completed in $(cat /tmp/buildah_fastest.txt) seconds
"
    echo
    read -p "Enter to continue"
    clear
}

buildah_medium() {
    echo
    echo_color "
In this example, we are going to mount in the containers/storage read/only from
the host into the containers as an additional store at /var/lib/shared.

The container can then use the images without having to pull them into it's own
local storage.  This gives you excellent security, with the same performance as
buildah_fast demonstration.

Pull an ubi8 image into shared read/only containers storage with host
"
    echo
    sudo rm -rf $MEDIUM
    sudo mkdir -p $MEDIUM
    sudo chcon -t container_file_t $MEDIUM
    read_color "    sudo podman run -v /var/lib/containers/storage:/var/lib/shared:ro -v $MEDIUM:/var/lib/containers quay.io/buildah/stable buildah pull ubi8"
    sudo /bin/time -o /tmp/buildah_medium.txt --format %e podman run -v /var/lib/containers/storage:/var/lib/shared:ro -v $MEDIUM:/var/lib/containers quay.io/buildah/stable buildah pull ubi8
    echo
    echo_color "
    Completed in $(cat /tmp/buildah_medium.txt) seconds
"

    echo
    read -p "Enter to continue"
    clear
}

buildah_medium_bud() {
    echo
    echo_color "
In this example, we are going to mount in the containers/storage read/only from
the host into the containers as an additional store at /var/lib/shared.

The container can then use the images without having to pull them into it's own
local storage.  This gives you excellent security, with the same performance as
buildah_fast demonstration.

Build a container image with shared read/only containers/storage.
"
    echo
    sudo rm -rf $MEDIUM
    sudo mkdir -p $MEDIUM
    sudo chcon -t container_file_t $MEDIUM
    read_color "    sudo podman run --device /dev/fuse -ti -v $PWD/Dockerfile:/Dockerfile:Z -v /var/lib/containers/storage:/var/lib/shared:ro -v $MEDIUM:/var/lib/containers quay.io/buildah/stable buildah bud /"
    sudo /bin/time podman -o /tmp/buildah_medium_bud.txt --format %e run --device /dev/fuse -ti -v $PWD/Dockerfile:/Dockerfile:Z -v /var/lib/containers/storage:/var/lib/shared:ro -v $MEDIUM:/var/lib/containers quay.io/buildah/stable buildah bud /

    echo_color "
    Completed in $(cat /tmp/buildah_medium_bud.txt) seconds
"
    echo
    read -p "Enter to continue"
    clear
}

buildah_medium_bud_with_overlay() {
    echo
    echo_color "
In this example, we are going to mount in the containers/storage read/only from
the host into the containers as an additional store at /var/lib/shared. We are
also using an OverlayMount of /var/cache/dnf to help speed up the dnf deployment
inside of the container.

Build a container image with shared read/only containers/storage with overlay mount.
"
    echo
    sudo rm -rf $MEDIUM
    sudo mkdir -p $MEDIUM
    sudo chcon -t container_file_t $MEDIUM
    read_color "    sudo podman run --device /dev/fuse -ti -v $PWD/Dockerfile:/Dockerfile:Z -v /var/lib/containers/storage:/var/lib/shared:ro -v $MEDIUM:/var/lib/containers quay.io/buildah/upstream buildah bud /"
    sudo /bin/time -o /tmp/buildah_medium_bud_with_overlay.txt --format "%e" podman run --device /dev/fuse -ti -v $PWD/Dockerfile:/Dockerfile:Z -v /var/lib/containers/storage:/var/lib/shared:ro -v $MEDIUM:/var/lib/containers quay.io/buildah/upstream buildah bud /

    echo_color "
    Completed in $(cat /tmp/buildah_medium_bud_with_overlay.txt) seconds
"
    echo
    read -p "Enter to continue"
    clear
}

speed_table() {
    echo "
    As you can see below, the slowest buildah pull to multiple times as long
    as the fastest, while the medium took relatively the same amount of time
    as the fastest.

    "
    printf "    _______________________________________\n"
    printf "    | %-10s | %-10s| %-10s |\n" "Slowest" "Medium" "Fastest"
    printf "    | ---------- | --------- | ---------- |\n"
    printf "    | %-10s | %-10s| %-10s |\n" $(cat /tmp/buildah_slowest.txt) $(cat /tmp/buildah_medium.txt) $(cat /tmp/buildah_fastest.txt) 
    printf "    |_____________________________________|\n"
    echo
    echo
    read -p "Enter to continue"
    clear
}

clean_temp_files() {
    sudo rm -rf /tmp/buildah*txt $SLOWEST $MEDIUM
}

clear

setup

intro

buildah_slowest

buildah_fastest

buildah_medium

echo_color "$(speed_table)"

echo

buildah_medium_bud

# buildah_medium_bud_with_overlay

# clean_images_and_containers

clean_temp_files

read -p "End of Demo!!!"
echo
echo "Thank you!"
