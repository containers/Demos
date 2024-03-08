#!/bin/sh -e

# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

storedir=/tmp/store
mkdir -p $storedir

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


DEFAULT_APP="lamp"
DEFAULT_REGISTRY="quay.io/rhatdan"
DEFAULT_IMAGE="quay.io/rhatdan/$APP"
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

REGISTRY=${REGISTRY:-${DEFAULT_REGISTRY}}
APP=${APP:-${DEFAULT_APP}}
TYPE=${TYPE:-${DEFAULT_TYPE}}
ARCH=${ARCH:-${DEFAULT_ARCH}}
VARIANT=${VARIANT}
OS=${OS:-${DEFAULT_OS}}
IMAGE=${REGISTRY}/${APP}

function init {
    sudo bash -c "dnf -y install podman zstd 2>&1 >/dev/null && dnf -y update podman zstd"
    read
    clear
}

function build {
    echo_color "
Build bootable OCI Image"
    if [ $APP == "machine" ]; then
	podman rmi --force --ignore localhost/fcos
	exec_color "cat $APP/Containerfile.fcos"
	exec_color "podman build --arch ${ARCH} --manifest localhost/fcos -f $APP/Containerfile.fcos $APP/"
	FROM="--from localhost/fcos "
    fi
    exec_color "cat $APP/Containerfile"
    exec_color "podman manifest exists ${IMAGE} && podman manifest rm ${IMAGE} || true"
    exec_color "podman rmi --force ${IMAGE}"
    exec_color "podman build --build-arg=\"SSHPUBKEY=$(cat $HOME/.ssh/id_rsa.pub)\" --arch=${ARCH} $FROM--manifest ${IMAGE} $APP/"
}

function test {
    echo_color "
Test bootable OCI image as a container"
    exec_color "podman run --pull=never --rm -ti ${IMAGE} sh"
}

function test_crun_vm {
    echo_color "
Test VM using crun-vm"
    tmpdir=$(mktemp -d);
    exec_color "cp ${PWD}/image/${APP}.${TYPE} $tmpdir/${APP}.${TYPE}"
    exec_color "podman --runtime crun-vm run -ti --rootfs $tmpdir"
    exec_color "rm -rf $tmpdir"
}

function push {
    echo_color "
Push generated manifest to container registry"
    exec_color "podman login $REGISTRY"
    exec_color "podman manifest push --all ${IMAGE}"
}

function create_disk_image {
    echo_color "
Creating Disk Image $1 with bootc-image-builder"
    TYPE=$1
    exec_color "sudo REGISTRY_AUTH_FILE=$XDG_RUNTIME_DIR/containers/auth.json podman run --rm -it --platform=${OS}/${ARCH} --privileged -v .:/output -v ${storedir}:/store --pull newer quay.io/centos-bootc/bootc-image-builder --type $TYPE ${IMAGE}:latest"
    exec_color "sudo chown -R $UID:$UID ."
    mkdir -p image
    new_image="image/$(basename ${IMAGE}).${TYPE}"
    exec_color "mv ${TYPE}/disk.${TYPE} ${new_image} 2>/dev/null || mv image/disk.* ${new_image}"
    exec_color "zstd --rm ${new_image}"
}

function create_manifest {
    echo_color "
Populate OCI manifest with artifact $1"
    TYPE=$1
    new_image="image/$(basename ${IMAGE}).${TYPE}.zst"
    exec_color "podman manifest add ${VARIANT} --os ${OS} --arch=${ARCH} --artifact --artifact-type application/x-qemu-disk --annotation disktype=${TYPE} ${IMAGE} ${new_image}"
}

function push_manifest {
    echo_color "
Push OCI manifest and artifacts to container registry"
    exec_color "podman manifest push --all ${IMAGE}"
}

function inspect {
    echo_color "
Inpspect the OCI Manigest"
    exec_color "skopeo inspect --raw docker://${IMAGE}:latest | json_pp"
}

function clone_containerfiles {
    echo_color "
Modify OCI Image ${IMAGE} to support cloud-init"
    exec_color "git clone https://gitlab.com/bootc-org/examples 2>/dev/null | (cd examples; git pull origin main)"
    exec_color "cat examples/cloud-init/Containerfile"
    exec_color "podman build --arch=${ARCH} --from ${IMAGE} -t ${IMAGE}-ami examples/cloud-init"
    echo_color "
Modify OCI Image ${IMAGE} to support nvidia"
    exec_color "cat examples/nvidia/Containerfile"
    exec_color "podman build --arch=${ARCH} --from ${IMAGE}-ami -t ${IMAGE}-nvidia examples/nvidia"
}

init
build
test
push
create_disk_image $TYPE
create_disk_image ami
create_manifest $TYPE
create_manifest ami
push_manifest
inspect
clone_containerfiles
test_crun_vm
