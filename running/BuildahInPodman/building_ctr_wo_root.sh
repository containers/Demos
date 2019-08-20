#!/usr/bin/env sh

# building_ctr_wo_root.sh demo script.
# This script will demonstrate how you can use
# a container to build container images as "root"
# inside of a container without actually being
# being root inside of the container. 

 
# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

read_color() {
    read -p "${bold}$1${reset}"
}

echo_color() {
    echo "${cyan}$1${reset}"
}

setup() {

    echo_color "Installing/updating container-selinux and Podman"
    echo
    read_color "yum -y install --enablerepo updates-testing container-selinux podman"
    yum -y install --enablerepo updates-testing container-selinux podman
    if [[ $? != 0 ]]; then
	echo $0 requires the podman and containers-selinux packages to be installed
	exit 1
    fi
    echo_color "Updating fuse"
    echo
    read_color "echo fuse > /usr/lib/modules-load.d/fuse-overlayfs.conf"
    echo fuse > /usr/lib/modules-load.d/fuse-overlayfs.conf
    clear
}

intro() {
    read -p "Running Building Container Images without being root Demo"
    echo
}


podman_runs_buildah() {

    /bin/cat <<- "EOF" > ./Dockerfile
FROM fedora
RUN yum -y install buildah --exclude container-selinux --enablerepo updates-testing; rm -rf /var/cache /var/log/dnf* /var/log/yum.*
RUN sed 's|^#mount_program|mount_program|g' -i /etc/containers/storage.conf
ENV _BUILDAH_STARTED_IN_USERNS="" BUILDAH_ISOLATION=chroot
COPY Dockerfile /root
EOF
    echo
    echo_color "Create image from a Dockerfile and run the container"
    echo_color "Let's look at our Dockerfile, note it copies itself into the container at /root"
    echo
    read_color "cat ./Dockerfile"
    cat ./Dockerfile

    echo
    echo_color "Let's create a directory to to mount a volume on"
    echo
    read_color "mkdir /var/lib/mycontainers"
    mkdir /var/lib/mycontainers

    echo 
    echo_color "Set the ownership of the directory"
    echo
    read_color "chown 5000:5000 /var/lib/mycontainers"
    chown 5000:5000 /var/lib/mycontainers

    echo
    echo_color "Create the \"buildahimage\" image from the Dockerfile"
    echo
    read_color "podman build -t buildahimage -f ./Dockerfile ."
    podman build -t buildahimage -f ./Dockerfile .

    echo
    echo_color "Run the container with the volume mounted into it for it's storage."
    echo_color "The Buildah container will run the same Dockerfile creating another"
    echo_color "container image."
    echo_color "This demonstrates building a container within a usernamespace with a locked"
    echo_color "down container.  This is the equivalent of running the build as UID=5000."

    echo
    read_color "podman run --net=host --device=/dev/fuse -v /var/lib/mycontainers:/var/lib/containers:Z -ti --uidmap 0:5000:1000 buildahimage buildah bud /root"
    podman run --net=host --device=/dev/fuse -v /var/lib/mycontainers:/var/lib/containers:Z -ti --uidmap 0:5000:1000 buildahimage buildah bud /root
    echo
    read_color "Press return to start cleanup process"
}


clean_images_and_containers() {

    read_color "podman rm -a -f"
    podman rm -a -f
    echo
    read_color "podman rmi -a -f"
    podman rmi -a -f

    echo
    read -p "Enter to continue"
    clear
}

clean_temp_files() {

    rm -rf ./Dockerfile
    rm -rf /var/lib/mycontainers
}

setup

intro

podman_runs_buildah

clean_images_and_containers

clean_temp_files

read -p "End of Demo!!!"
echo
echo "Thank you!"

