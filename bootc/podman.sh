#!/bin/sh
#!/bin/sh

# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

read_color() {
    read -p "${bold}$1${reset}"
}

exec_color() {
    echo -n "
${bold}$ $1${reset}"
    read 
    bash -c "$1"
}

echo_color() {
    echo "${cyan}$1${reset}"
}

IMAGE=quay.io/rhatdan/podman-machine
clear
exec_color "podman login quay.io"
exec_color "cat machine/Containerfile.fcos"
exec_color "podman build -t fcos -f machine/Containerfile.fcos machine/"
exec_color "cat machine/Containerfile"
exec_color "podman build --from fcos -t $IMAGE machine/"
exec_color "podman run --rm -ti $IMAGE sh"
clear
exec_color "podman push $IMAGE"
exec_color "sudo podman run --rm -it --privileged -v .:/output --pull newer quay.io/centos-bootc/bootc-image-builder --type qcow2 $IMAGE:latest"
exec_color "sudo chown -R $UID:$UID qcow2"
exec_color "mv qcow2/disk.qcow2 qcow2/$(basename $IMAGE).qcow2"
