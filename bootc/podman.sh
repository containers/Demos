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


IMAGE="quay.io/rhatdan/podman-machine"
TYPE="qcow2"
ARCH="$(uname -m)"
VARIANT=""
OS=$(uname)
OS=${OS,,}


OPTSTRING=":a:i:o:v:"

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    i)
      IMAGE="${OPTARG}"
      ;;
    a)
      ARCH="${OPTARG}"
      ;;
    o)
      OS="${OPTARG}"
      ;;
    v)
      VARIANT="--variant ${OPTARG}"
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done

clear
exec_color "podman login quay.io"
exec_color "cat machine/Containerfile.fcos"
exec_color "podman build --arch ${ARCH} -t localhost/fcos -f machine/Containerfile.fcos machine/"
exec_color "cat machine/Containerfile"
exec_color "podman build --arch=${ARCH} --from localhost/fcos -t ${IMAGE} machine/"
exec_color "podman run --arch=${ARCH} --rm -ti ${IMAGE} sh"
clear
exec_color "podman push ${IMAGE}"
exec_color "sudo podman run --rm -it --platform=${ARCH} --privileged -v .:/output --pull newer quay.io/centos-bootc/bootc-image-builder--type ${TYPE} ${IMAGE}:latest"
exec_color "sudo chown -R $UID:$UID ${TYPE}"
exec_color "mv ${TYPE}/disk.${TYPE} ${TYPE}/$(basename ${IMAGE}).${TYPE}"
exec_color "podman manifest add ${VARIANT} --os ${OS} --arch=${ARCH} --artifact ${IMAGE} --artifact-type application/x-qemu-disk --annotation disktype=${TYPE} ${TYPE}/$(basename ${IMAGE}).${TYPE}"
exec_color "podman manifest push --all ${IMAGE}"
