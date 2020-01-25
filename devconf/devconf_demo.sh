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

# POD=
# # only remove images if they were added by this script
# UBUNTU_RMI=false
# UBI8_RMI=false
# FEDORA_DOCKER_RMI=false
# FEDORA_PODMAN_RMI=false
# BUILDAH_CTR_RMI=false
# cleanup() {
#     echo_bright "--> cleanup"
#     echo ""
#     sudo rm -f /etc/audit/rules.d/audit-demo.rules
#     sudo augenrules --load > /dev/null
#     sudo systemctl restart auditd 2> /dev/null
#     sudo rm -f a_file_owned_by_root
#     rm -rf "$PWD"/myvol
#     if $BUILDAH_CTR_RMI; then
#         sudo podman rmi buildah/stable
#     fi
#     if $FEDORA_DOCKER_RMI; then
#         sudo docker rmi fedora:latest
#     fi
#     if $FEDORA_PODMAN_RMI; then
#         sudo podman rmi fedora:latest
#     fi
#     if $UBUNTU_RMI; then
#         sudo docker rmi ubuntu:latest
#     fi
#     if $UBI8_RMI; then
#         podman rmi ubi8-minimal
#     fi
#     if sudo podman images | grep ubuntu | grep demo; then
#         sudo podman rmi ubuntu:demo
#     fi
#     if [ ! -z $POD ]; then
#         sudo crictl stopp $POD
#         sudo crictl rmp $POD
#     fi
#     sudo podman stop -t 0 --all 2> /dev/null
#     sudo podman rm -f --all 2> /dev/null
#     sudo systemctl restart docker
# }

# trap cleanup EXIT
# Initial setup
setup() {
    # if ! rpm -q podman buildah audit >/dev/null; then
	# echo "$0" requires the podman, buildah and audit packages be installed
	# exit 1
    # fi
    # if ! command -v docker > /dev/null; then
	# echo "$0" requires the docker package be installed
	# exit 1
    # fi
    # sudo cp /usr/share/doc/audit/rules/10-base-config.rules /etc/audit/rules.d/audit-demo.rules
    # sudo augenrules --load > /dev/null
    # sudo systemctl restart auditd 2> /dev/null
    if ! sudo docker images | grep ubuntu | grep latest; then
	# UBUNTU_RMI=true
        sudo docker pull ubuntu:latest
    fi
    if ! sudo docker images | grep fedora | grep latest; then
	# FEDORA_DOCKER_RMI=true
	sudo docker pull fedora:latest
    fi
    if ! sudo podman images | grep fedora | grep latest; then
	# FEDORA_PODMAN_RMI=true
	sudo podman pull fedora:latest
    fi
    if ! sudo podman images | grep quay.io/buildah/stable | grep latest; then
	# FEDORA_PODMAN_RMI=true
	sudo podman pull quay.io/buildah/stable
    fi
    # sudo touch a_file_owned_by_root
    # sudo chmod 0600 a_file_owned_by_root
    # clear
}

# buildah_image() {
#     if ! sudo podman images  | grep -q -w buildah-ctr; then
# 	# BUILDAH_CTR_RMI=true
# 	sudo podman pull quay.io/buildah/stable
#     fi
# }

intro() {
    read_yellow "Demos!  Buildah, Podman, Skopeo, CRI-O Features!"
    echo ""
    clear
}

buildah_dockerfile_in() {
    # buildah bud with dockerfile.in
    read_yellow "Buildah bud with Dockerfile.in"
    echo ""

    read_bright "--> cat Fedora.in"
    cat Fedora.in
    echo ""

    read_bright "--> cat Ubuntu.in"
    cat Ubuntu.in
    echo ""

    read_bright "--> cat dockerfile"
    cat dockerfile
    echo ""

    read_bright "--> sudo buildah bud -t myubuntu -f Ubuntu.in ."
    sudo buildah bud -t myubuntu -f Ubuntu.in .
    echo ""

    read_bright "--> sudo buildah images"
    buildah images
    echo ""

    read_bright "--> sudo buildah bud -t myfedora -f Fedora.in ."
    sudo buildah bud -t myfedora -f Fedora.in .
    echo ""

    read_bright "--> sudo buildah images"
    sudo buildah images
    echo ""

    read_bright "--> clear"
    clear
}

buildah_additional_stores() {
    # buildah additional stores
    read_yellow "Buildah bud with additional stores"
    echo ""

    read_bright "--> time sudo podman run quay.io/buildah/stable buildah pull alpine"
    time sudo podman run quay.io/buildah/stable buildah pull alpine
    echo ""

    read_bright "--> time sudo podman run -v /var/lib/containers:/var/lib/containers --security-opt label=disable quay.io/buildah/stable buildah pull alpine"
    time sudo podman run -v /var/lib/containers:/var/lib/containers --security-opt label=disable quay.io/buildah/stable buildah pull alpine
    echo ""

    read_bright "--> time sudo podman run -v /var/lib/containers/storage:/var/lib/shared:ro quay.io/buildah/stable buildah pull alpine"
    time sudo podman run -v /var/lib/containers/storage:/var/lib/shared:ro quay.io/buildah/stable buildah pull alpine
    echo ""

    read_bright "--> cleanup"
    sudo podman rm -a -f 2> /dev/null
    sudo podman stop -t 0 --all 2> /dev/null
    sudo podman rm -f --all 2> /dev/null
    echo ""

    read_bright "--> clear"
    clear
}

podman_pod() {
    # Podman pod commands
    read_yellow "Podman pod features"
    echo ""

    read_bright "--> sudo podman pod create"
    pod=$(sudo podman pod create)
    echo "${pod}"
    echo ""

    read_bright "--> sudo podman pod list"
    sudo podman pod list
    echo ""

    read_bright "--> sudo podman ps --all --pod"
    sudo podman ps --all --pod
    echo ""

    read_bright "--> sudo podman run -dt --pod ${pod} alpine top"
    sudo podman run -dt --pod ${pod} alpine top
    echo ""

    read_bright "--> sudo podman pod ps"
    sudo podman pod ps
    echo ""

    read_bright "--> sudo podman pod ps --all --pod"
    sudo podman pod ps --all --pod
    echo ""

    read_bright "--> cleanup"
    sudo podman rm -a -f 2> /dev/null
    sudo podman stop -t 0 --all 2> /dev/null
    sudo podman rm -f --all 2> /dev/null
    echo ""

    read_bright "--> clear"
    clear
}

# podman_generate_systemd() {
#     read_yellow "Let's create a systemd service to run a container image"
#     echo ""

#     read_bright "--> podman generate systemd --help"
#     podman generate systemd --help
#     echo ""

#     read_bright "--> podman create -d --name topservice alpine:latest top"
#     podman create -d --name topservice alpine:latest top
#     echo ""

#     read_bright "--> podman generate systemd --name topservice > ~/.config/systemd/user/sometop.service"
#     podman generate systemd --name topservice > ~/.config/systemd/user/sometop.service
#     echo ""

#     read_bright "--> check out ~/.config/systemd/user/sometop.service"
#     cat ~/.config/systemd/user/sometop.service
#     echo ""

#     read_bright "--> systemctl --user daemon-reload"
#     systemctl --user daemon-reload
#     echo ""

#     read_bright "--> systemctl --user start sometop.service"
#     systemctl --user start sometop.service
#     echo ""

#     read_bright "--> journalctl --user-unit sometop.service"
#     journalctl --user-unit sometop.service
#     echo ""


# }

podman_generate_systemd() {
    read_yellow  "Let's create a systemd service to run a container image"
    echo ""

    read_yellow "podman generate systemd help menu"
    read_bright "--> podman generate systemd --help"
    podman generate systemd --help
    echo ""

    read_yellow "podman create -d --name topservice alpine:latest top"
    read_bright "--> podman create -d --name topservice alpine:latest top"
    podman create -d --name topservice alpine:latest top
    echo ""

    read_bright "--> podman generate systemd --name topservice > ~/.config/systemd/user/sometop.service"
    podman generate systemd --name topservice > ~/.config/systemd/user/sometop.service
    echo ""

    read_bright "--> check out ~/.config/systemd/user/sometop.service"
    cat ~/.config/systemd/user/sometop.service
    echo ""

    read_bright "--> systemctl --user daemon-reload"
    systemctl --user daemon-reload
    echo ""

    read_bright "--> systemctl --user start sometop.service"
    systemctl --user start sometop.service
    echo ""

    read_bright "--> journalctl --user-unit sometop.service"
    journalctl --user-unit sometop.service
    echo ""

    read_bright "--> systemctl --user stop sometop.service"
    systemctl --user stop sometop.service
    echo ""

    read_bright "--> podman ps -a"
    podman ps -a
    echo ""

    read_bright "--> systemctl --user start sometop.service"
    systemctl --user start sometop.service
    echo ""

    read_bright "--> podman ps -a"
    podman ps -a
    echo ""

    read_bright "--> podman logs topservice"
    podman logs topservice
    echo ""

    read_bright "--> clear"
    clear
}

podman_cgroupsv1() {
    read_yellow "Rootless podman with cgroupsV1"
    echo ""

    read_bright "--> podman run --detach --memory 4M alpine sleep 1000"
    podman run --detach --memory 4M alpine sleep 1000
    echo ""

    read_bright "--> cleanup"
    sudo podman rm -a -f 2> /dev/null
    sudo podman stop -t 0 --all 2> /dev/null
    sudo podman rm -f --all 2> /dev/null
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

crio_infra_container() {
    read_yellow "CRI-O with and without infra container"
    echo ""

    read_bright "--> vi /etc/crio/crio.conf"
    vi /etc/crio/crio.conf
    sudo systemctl restart crio
    echo ""

    read_bright "--> vi sandbox_config.json"
    vi sandbox_config
    echo ""

    read_bright "--> POD=\$(sudo crictl runp sandbox_config.json)"
    POD=$(sudo crictl runp sandbox_config.json)
    echo "$POD"
    echo ""

    read_bright "--> sudo runc list"
    sudo runc list
    echo ""

    read_bright "--> cleanup"
    sudo crictl stopp $POD
    sudo crictl rmp $POD
    echo ""

    read_bright "--> vi sandbox_config.json"
    vi sandbox_config
    echo ""

    read_bright "--> POD=\$(sudo crictl runp sandbox_config.json)"
    POD=$(sudo crictl runp sandbox_config.json)
    echo "$POD"
    echo ""

    read_bright "--> sudo runc list"
    sudo runc list
    echo ""

    read_bright "--> cleanup"
    sudo crictl stopp $POD
    sudo crictl rmp $POD
    echo ""

    read_bright "--> clear"
    clear
}

crio_conf() {
    read_yellow "CRI-O's config file"
    echo ""

    read_bright "--> vi /etc/crio/crio.conf"
    vi /etc/crio/crio.conf
    echo ""

    read_bright "--> clear"
    clear
}

setup
intro
buildah_dockerfile_in
buildah_additional_stores
podman_pod
podman_generate_systemd
podman_cgroupsv1
skopeo_cp_from_docker_to_podman
crio_infra_container
crio_conf

read_yellow "End of Demo"
echo_bright "Thank you!"
