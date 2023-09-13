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

cpuweight() {
    sudo systemctl set-property --runtime QM.slice CPUWeight=50
    sudo systemctl set-property --runtime qm.service CPUWeight=50
    exec_color "sudo cat /sys/fs/cgroup/QM.slice/cpu.weight"
    exec_color "sudo cat /sys/fs/cgroup/QM.slice/qm.service/cpu.weight"
    exec_color "sudo systemctl set-property --runtime QM.slice CPUWeight=10"
    exec_color "sudo cat /sys/fs/cgroup/QM.slice/cpu.weight"
    exec_color "sudo cat /sys/fs/cgroup/QM.slice/qm.service/cpu.weight"
    read
}

podman() {
    clear
    exec_color "sudo podman exec -ti qm ps -eZ"
    exec_color "sudo podman exec qm id | grep --color qm_t"
    exec_color "sudo podman exec qm podman run alpine echo hi"
    exec_color "sudo podman run ubi9 echo hi"
    exec_color "sudo podman exec qm podman images"
    exec_color "sudo podman images"
    exec_color "sudo podman exec qm podman run --userns=auto alpine cat /proc/self/uid_map"
    exec_color "sudo podman exec qm podman run --userns=auto alpine cat /proc/self/uid_map"
    exec_color "sudo podman exec qm podman run --userns=auto alpine cat /proc/self/uid_map"
    exec_color "sudo podman run --userns=auto ubi9 cat /proc/self/uid_map"
    exec_color "sudo podman run --userns=auto ubi9 cat /proc/self/uid_map"
    exec_color "sudo podman exec -ti qm sh"
}

hirte() {
    clear
    exec_color "sudo hirtectl list-units | grep --color running"
    exec_color "sudo podman exec -ti qm podman pull ubi8/httpd-24"
    rootfs=/usr/lib/qm/rootfs
    exec_color "echo \"[Container]
Image=registry.access.redhat.com/ubi8/httpd-24
Network=host
\" > /tmp/myquadlet.container"

    exec_color "sudo podman cp /tmp/myquadlet.container qm:/etc/containers/systemd/"
    exec_color "sudo podman exec qm systemctl daemon-reload"
    exec_color "sudo hirtectl restart qm.fedora myquadlet.service"
    exec_color "sudo hirtectl list-units | grep --color myquadlet"
    exec_color "curl 127.0.0.1:8080"
    exec_color "sudo hirtectl stop qm.fedora myquadlet.service"
    exec_color "sudo hirtectl list-units | grep --color myquadlet"
}

#init

#install

#setup

status

cpuweight

podman

hirte

echo done
read
