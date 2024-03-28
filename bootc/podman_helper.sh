#!/bin/bash

set -eou pipefail
IFS=$'\n\t'

# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

storedir=/tmp/store
mkdir -p "${storedir}"

read_color() {
    read -r "${bold}$1${reset}"
}

exec_color() {
    echo -n "
${bold}$ $1${reset}"
    read -r
    bash -c "$1"
}

echo_color() {
    echo "${cyan}$1${reset}"
}

DEFAULT_REGISTRY="quay.io/rhatdan"
DEFAULT_TYPE="qcow2"
DEFAULT_ARCH=$(uname -m)
DEFAULT_VARIANT=""
DEFAULT_OS=$(uname)

OPTSTRING=":a:hr:o:v:A:t:"
function help {
	echo -n "
Valid options:

-A APP
-a ARCH
-o OS
-r REGISTRY
-v VARIANT
"
}

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    r)
      REGISTRY="${OPTARG}"
      shift; shift
      ;;
    a)
      ARCH="${OPTARG}"
      shift; shift
      ;;
    A)
      APP="${OPTARG}"
      shift; shift
      ;;
    o)
      OS="${OPTARG}"
      shift; shift
      ;;
    v)
      VARIANT="--variant ${OPTARG}"
      shift; shift
      ;;
    h)
      help; exit 0
      ;;
    ?)
      echo "
Invalid option: -${OPTARG}."
      help; exit 1
      ;;
  esac
done

REGISTRY=${REGISTRY:-${DEFAULT_REGISTRY}}
APP=${APP:-${DEFAULT_APP}}
ARCH=${ARCH:-${DEFAULT_ARCH}}
OS=${OS:-${DEFAULT_OS}}
REGISTRY=${REGISTRY:-${DEFAULT_REGISTRY}}
TYPE=${TYPE:-${DEFAULT_TYPE}}
VARIANT=${VARIANT-${DEFAULT_VARIANT}}
IMAGE=${REGISTRY}/${APP}:1.0

function init {
    rm -rf /tmp/podman.demo*
    if ! rpm -q --quiet podman && ! rpm -q --quiet zstd; then
        sudo bash -c "dnf -y install podman zstd && dnf -y update podman zstd" &>/dev/null
        clear
    fi
}

function login {
    echo_color "
Push generated manifest to container registry"
    exec_color "podman login ${REGISTRY}"
}

function push {
    image=${1:-${IMAGE}}
    exec_color "podman manifest push --all ${image}"
}

function demo {
    echo_color "

Time for video

"
    read -r
}

function create_disk_image {
    echo_color "
Creating disk images $1 with bootc-image-builder"
    exec_color "sudo podman run -v $XDG_RUNTIME_DIR/containers/auth.json:/run/containers/0/auth.json --rm -it --platform=${OS}/${ARCH} --privileged -v .:/output -v ${storedir}:/store --pull newer quay.io/centos-bootc/bootc-image-builder $_TYPE --chown $UID:$UID ${IMAGE} "
}

function rename {
    _TYPE=$1
    mkdir -p image
    new_image="image/$(basename "${IMAGE}").${_TYPE}"
    exec_color "mv ${_TYPE}/disk.${_TYPE} ${new_image} 2>/dev/null || mv image/disk.* ${new_image}"
    exec_color "zstd -f --rm ${new_image}"
}

function clone_containerfiles {
    echo_color "
Modify OCI Image ${IMAGE} to support cloud-init"
    exec_color "git clone https://gitlab.com/bootc-org/examples 2>/dev/null || (cd examples; git pull origin main)"
    exec_color "cat examples/cloud-init/Containerfile"
    exec_color "podman build --arch=${ARCH} --from ${IMAGE} -t ${IMAGE}-ami examples/cloud-init"
    echo_color "
Modify OCI Image ${IMAGE} to support nvidia"
    exec_color "cat examples/nvidia/Containerfile"
    exec_color "podman build --arch=${ARCH} --from ${IMAGE}-ami -t ${IMAGE}-nvidia examples/nvidia"
}

function create_manifest {
    echo_color "
Populate OCI manifest with artifact $1"
    _TYPE=$1
    new_image="image/$(basename "${IMAGE}").${_TYPE}.zst"
    exec_color "podman manifest add ${VARIANT} --os ${OS} --arch=${ARCH} --artifact --artifact-type application/x-qemu-disk --annotation disktype=${_TYPE} ${IMAGE} ${new_image}"
}

function push_manifest {
    echo_color "
Push OCI manifest and artifacts to container registry"
    exec_color "podman manifest push --all ${IMAGE}"
}

function inspect {
    echo_color "
Inspect the OCI Manigest"
    exec_color "skopeo inspect --raw docker://${IMAGE}:1.1 | json_pp"
}

function oci_test {
    echo_color "
Test bootable OCI image as a container"
    exec_color "podman run --privileged --pull=never --rm -t ${IMAGE}"
}

