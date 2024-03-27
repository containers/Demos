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

DEFAULT_APP="lamp"
DEFAULT_REGISTRY="quay.io/rhatdan"
DEFAULT_TYPE="qcow2"
DEFAULT_ARCH=$(uname -m)
DEFAULT_VARIANT=""
DEFAULT_OS=$(uname)

OPTSTRING=":a:hr:o:v:A:"
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
TYPE=${TYPE:-${DEFAULT_TYPE}}
ARCH=${ARCH:-${DEFAULT_ARCH}}
VARIANT=${DEFAULT_VARIANT}
OS=${OS:-${DEFAULT_OS}}
IMAGE=${REGISTRY}/${APP}


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
	exec_color "podman build --arch ${ARCH} --manifest localhost/fcos -f $APP/Containerfile.fcos $APP/"
	FROM="--from localhost/fcos "
    fi
    exec_color "cat $APP/Containerfile"
    exec_color "podman manifest exists ${IMAGE} && podman manifest rm ${IMAGE} || true"
    exec_color "podman rmi --force ${IMAGE}"
    exec_color "podman build --build-arg=\"SSHPUBKEY=$(cat "${HOME}/.ssh/id_rsa.pub")\" --arch=${ARCH} ${FROM}--manifest ${IMAGE} ${APP}/"
}

function rebuild {
    echo_color "
Rebuild bootable OCI Image with fixed services enabled"
    exec_color "sed 's/^#RUN systemctl/RUN systemctl/' ${APP}/Containerfile | podman build --build-arg=\"SSHPUBKEY=$(cat "${HOME}/.ssh/id_rsa.pub")\" --file - --arch=${ARCH} --manifest ${IMAGE} ${APP}/"
}

function oci_test {
    echo_color "
Test bootable OCI image as a container"
    exec_color "podman run --privileged --pull=never --rm -t ${IMAGE}"
    exec_color "echo oops"
}

function test_crun_vm {
    echo_color "
Test VM using crun-vm"
    tmpdir=$(mktemp -d /tmp/podman.demo-XXXXX);
    exec_color "zstd -d ${PWD}/image/${APP}.${TYPE}.zst -o ${tmpdir}/${APP}.${TYPE}"
    echo_color "
After starting the next command you will need to go to another terminal and run podman commands against the
VM to test it.

podman exec -ti -l /bin/sh

Eventually

podman stop -l

"

    exec_color "podman --runtime crun-vm run -ti --rootfs ${tmpdir}"
    exec_color "rm -rf ${tmpdir}"
}

function push {
    echo_color "
Push generated manifest to container registry"
    exec_color "podman login ${REGISTRY}"
    exec_color "podman manifest push --all ${IMAGE}"
}
function demo {
    echo_color "

Time for video

"
    read -r
}

function create_disk_image {
    echo_color "
Creating Disk Image $1 with bootc-image-builder"
    TYPE=$1
    exec_color "sudo REGISTRY_AUTH_FILE=$XDG_RUNTIME_DIR/containers/auth.json podman run --rm -it --platform=${OS}/${ARCH} --privileged -v .:/output -v ${storedir}:/store --pull newer quay.io/centos-bootc/bootc-image-builder --type $TYPE --chown $UID:$UID ${IMAGE}:latest "
    mkdir -p image
    new_image="image/$(basename "${IMAGE}").${TYPE}"
    exec_color "mv ${TYPE}/disk.${TYPE} ${new_image} 2>/dev/null || mv image/disk.* ${new_image}"
    exec_color "zstd -f --rm ${new_image}"
}

function create_manifest {
    echo_color "
Populate OCI manifest with artifact $1"
    TYPE=$1
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
    exec_color "skopeo inspect --raw docker://${IMAGE}:latest | json_pp"
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
    exec_color "git clone https://github.com/redhat-et/locallm 2>/dev/null || (cd locallm; git pull origin main)"
    exec_color "cd locallm; bash"
}


case "${1:-""}" in
    1)
	init
	build
	oci_test
	;;
    2)
	push
	demo
	rebuild
	push
	demo
	;;
    3)
	create_disk_image "${TYPE}"
	test_crun_vm
	;;
    4)
	create_disk_image ami
	create_manifest "${TYPE}"
	create_manifest ami
	push_manifest
	inspect
	;;
    5)
	clone_containerfiles
	;;
    6)
	clone_ai
	;;
    *)
	echo_color "
Two run this demonstration users must specify specific sections to demonstrate

    1) Build a bootable OCI Container image and then testing it as an OCI container image
    2) Push the container image to a container registry, demonstrate converting a running
       AMI to the bootable container image. Then updating the image and rebuilding it.
    3) Convert the OCI Image to an $TYPE and test the image locally using crun-vm to make
       sure the image works proplery.
    4) Convert the OCI Image to an AMI disk image, add the $TYPE and AMI diskimage to the
       OCI image manifest and finally push the OCI Manifest and the disk images to a
       container registry. Finally inspect the manifest to see how tools could pull down
       specific images.
    5) Add cloud-init and nvidia libraries to make it easier to run your image in the cloud
       with Nvidia GPUs.
    6) Explore and run containers using content from the Red Hat AI Studio on Linux.
"

	;;
esac
