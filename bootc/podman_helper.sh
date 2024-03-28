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
      ;;
    a)
      ARCH="${OPTARG}"
      ;;
    A)
      APP="${OPTARG}"
      ;;
    o)
      OS="${OPTARG}"
      ;;
    v)
      VARIANT="--variant ${OPTARG}"
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

# shift all the args so we can use positional args after the flags (i.e. ./podman.sh -r string -A string 1)
shift $((OPTIND - 1));

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
        sudo bash -c "dnf -y install podman git zstd && dnf -y update podman git zstd" &>/dev/null
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
    if [ -f "${XDG_RUNTIME_DIR}/containers/auth.json" ]; then
        AUTH_JSON="${XDG_RUNTIME_DIR}/containers/auth.json"
    else
        AUTH_JSON="${HOME}/.docker/config.json"
    fi
    echo_color "
Creating disk images $1 with bootc-image-builder"
    exec_color "sudo podman run -v ${AUTH_JSON}:/run/containers/0/auth.json --rm -it --platform=${OS}/${ARCH} --privileged -v .:/output -v ${storedir}:/store --pull newer quay.io/centos-bootc/bootc-image-builder $1 --chown ${UID}:${UID} ${IMAGE} "
}

function rename {
    mkdir -p image
    new_image="image/$(basename "${IMAGE}").${TYPE}"
    exec_color "mv ${TYPE}/disk.${TYPE} ${new_image} 2>/dev/null || mv image/disk.* ${new_image}"
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
    new_image="image/$(basename "${IMAGE}").${TYPE}.zst"
    exec_color "podman manifest add ${VARIANT} --os ${OS} --arch=${ARCH} --artifact --artifact-type application/x-qemu-disk --annotation disktype=${TYPE} ${IMAGE} ${new_image}"
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

