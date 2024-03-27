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

DEFAULT_APP="inference"
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
        sudo bash -c "dnf -y install podman zstd && dnf -y update podman zstd" &>/dev/null
        clear
    fi
}

function build {
    echo_color "
Build bootable OCI Image"

    FROM=""
    if [ "${APP}" == "machine" ]; then
	podman rmi --force --ignore localhost/fcos
	exec_color "cat $APP/Containerfile.fcos"
	exec_color "podman build --env REGISTRY --arch ${ARCH} --manifest localhost/fcos -f $APP/Containerfile.fcos $APP/"
	FROM="--from localhost/fcos "
    fi
    exec_color "cat $APP/Containerfile"

    exec_color "podman manifest exists ${IMAGE} && podman manifest rm ${IMAGE} || podman rmi --force ${IMAGE}"

    exec_color "podman build --security-opt label=disable -v $HOME/.local/share/containers:/tmp/containers -v $XDG_RUNTIME_DIR/containers/auth.json:/run/containers/0/auth.json:z --no-cache --cap-add SYS_ADMIN --build-arg TAG=1.0 --build-arg \"SSHPUBKEY=$(cat $HOME/.ssh/id_rsa.pub)\"  --build-arg=\"REGISTRY=$REGISTRY\" --arch=${ARCH} $FROM--manifest ${IMAGE} $APP/"
}

function oci_test {
    echo_color "
Test bootable OCI image as a container"
    exec_color "podman run --privileged --pull=never --rm -t ${IMAGE}"
    exec_color "echo oops"
}

function login {
    echo_color "
Push generated manifest to container registry"
    exec_color "podman login $REGISTRY"
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
    _TYPE=$1
    exec_color "sudo podman run -v $XDG_RUNTIME_DIR/containers/auth.json:/run/containers/0/auth.json --rm -it --platform=${OS}/${ARCH} --privileged -v .:/output -v ${storedir}:/store --pull newer quay.io/centos-bootc/bootc-image-builder $_TYPE --chown $UID:$UID ${IMAGE} "
}

function rename {
    _TYPE=$1
    mkdir -p image
    new_image="image/$(basename ${IMAGE}).${_TYPE}"
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

function clone_ai {
    echo_color "
Clone AI and explore what is available for use with the Podman Desktop AI Studio"
    exec_color "git clone https://github.com/containers/ai-lab-recipes 2>/dev/null || (cd ai-lab-recipes; git pull origin main)"

    exec_color " podman build --build-arg MODEL_URL=https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.1-GGUF/resolve/main/mistral-7b-instruct-v0.1.Q4_K_S.gguf -t ${REGISTRY}/mymodel ai-lab-recipes/models"

    exec_color "podman push ${REGISTRY}/mymodel:1.0"

    exec_color "podman build -t ${REGISTRY}/playground:1.0 ai-lab-recipes/playground"

    exec_color "podman push ${REGISTRY}/playground:1.0"

    exec_color "podman build -t ${REGISTRY}/rag-langchain:1.0 -f ai-lab-recipes/chatbot-langchain/builds/Containerfile ai-lab-recipes/chat-langchain"

    exec_color "podman push ${REGISTRY}/rag-langchain:1.0"
}


case "${1:-""}" in
    1)
	init
	login
	clone_ai
	;;
    2)
	build
	oci_test
	;;
    3)
	push
	;;
    4)
	create_disk_image "--type $TYPE --type ami"
	rename $TYPE
	rename ami
	;;
    5)
	clone_containerfiles
	;;
    *)
	echo_color "
Users must specify specific sections to demonstrate 1-6 to run this demonstration.

    1) Build a bootable OCI Container image and then testing it as an OCI container image
    2) Push the container image to a container registry, demonstrate converting a running
       AMI to the bootable container image. Then updating the image and rebuilding it.
    3) Convert the OCI Image to an $TYPE and test the image locally using crun-vm to make
       sure the image works proplery.
    4) Add cloud-init and nvidia libraries to make it easier to run your image in the cloud
       with Nvidia GPUs.
    5) Explore and run containers using content from the Red Hat AI Studio on Linux.
"

	;;
esac
