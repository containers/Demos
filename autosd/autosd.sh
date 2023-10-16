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

init() {
    sudo systemctl stop qm > /dev/null
    sudo podman rm qm --force -t 0 > /dev/null
    sudo podman volume rm --force qmEtc qmVar > /dev/null
    sudo rm -rf /usr/lib/qm > /dev/null
}

install() {
    echo_color "Installing qm packages"
    exec_color "sudo dnf -y install qm; sudo dnf -y update qm"
    exec_color "rpm -q qm"
    read
    clear
}

setup() {
    echo_color "Executing setup"
    echo_color "Enable hirte on the host system"
    exec_color "sudo systemctl start hirte hirte-agent"
    echo
    echo_color "Install and setup /usr/lib/qm/rootfs"
    exec_color "sudo /usr/share/qm/setup"
    read
    clear
}

status() {
    exec_color "sudo systemctl status qm.service"
    clear
}

status() {
    exec_color "sudo systemctl status qm.service"
    clear
}

podman() {
    clear
    exec_color "podman run --device /dev/fuse --replace --cap-add=all --name autosd --security-opt label=disable -d  quay.io/centos-sig-automotive/autosd:latest"
    exec_color "podman exec -ti autosd bash"
    exec_color "echo \"
[Container]
Image=registry.access.redhat.com/ubi8/httpd-24
AddDevice=/dev/fuse
Network=host
PublishPort=8080:80
[Install]
WantedBy=default.target
\" > ./myquadlet.container"
    exec_color "echo \"
from quay.io/centos-sig-automotive/autosd
run podman --root /usr/lib/qm/rootfs/var/lib/containers/storage pull registry.access.redhat.com/ubi8/httpd-24
add myquadlet.container  /usr/lib/qm/rootfs/etc/containers/systemd/
\" > ./Containerfile"
    exec_color "podman build --cap-add sys_admin -t autosd ."
    exec_color "podman run --device /dev/fuse --replace --cap-add=all --network=host --name autosd --security-opt label=disable -d  quay.io/centos-sig-automotive/autosd:latest"
    exec_color "podman exec autosd podman exec qm systemctl status myquadlet.service"
    exec_color "firefox localhost:8080"
    exec_color "podman stop autosd"
}

podman

echo done
read
