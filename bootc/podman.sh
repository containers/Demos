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

step=1

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
    rm -rf /tmp/podman.demo*
    sudo bash -c "dnf -y install podman zstd && dnf -y update podman zstd" &>/dev/null
    clear
}

function ctr (
    echo -n $step
    ((step+=1))
)

function build {
    echo_color "
Step $(ctr): Build bootable OCI Image"
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

function rebuild {
    echo_color "
Step $(ctr): Rebuild bootable OCI Image with fixed services enabled"
    exec_color "sed 's/^#RUN systemctl/RUN systemctl/' $APP/Containerfile | podman build --build-arg=\"SSHPUBKEY=$(cat $HOME/.ssh/id_rsa.pub)\" --file - --arch=${ARCH} --manifest ${IMAGE} $APP/"
}

function oci_test {
    echo_color "
Test bootable OCI image as a container"
    exec_color "podman run --privileged --pull=never --rm -t ${IMAGE}"
    exec_color "echo oops"
}

function test_crun_vm {
    echo_color "
Step $(ctr): Test VM using crun-vm"
    tmpdir=$(mktemp -d /tmp/podman.demo-XXXXX);
    exec_color "zstd -d ${PWD}/image/${APP}.${TYPE}.zst -o $tmpdir/${APP}.${TYPE}"
    echo_color "
After starting the next command you will need to go to another terminal and run podman commands against the
VM to test it.

podman exec -ti -l /bin/sh

Eventually

podman stop -l

"

    exec_color "podman --runtime crun-vm run -ti --rootfs $tmpdir"
    exec_color "rm -rf $tmpdir"
}

function push {
    echo_color "
Step $(ctr): Push generated manifest to container registry"
    exec_color "podman login $REGISTRY"
    exec_color "podman manifest push --all ${IMAGE}"
}
function demo {
    echo_color "

Time for video

"
}

function create_disk_image {
    echo_color "
Step $(ctr): Creating Disk Image $1 with bootc-image-builder"
    TYPE=$1
    exec_color "sudo REGISTRY_AUTH_FILE=$XDG_RUNTIME_DIR/containers/auth.json podman run --rm -it --platform=${OS}/${ARCH} --privileged -v .:/output -v ${storedir}:/store --pull newer quay.io/centos-bootc/bootc-image-builder --type $TYPE --chown $UID:$UID ${IMAGE}:latest "
    mkdir -p image
    new_image="image/$(basename ${IMAGE}).${TYPE}"
    exec_color "mv ${TYPE}/disk.${TYPE} ${new_image} 2>/dev/null || mv image/disk.* ${new_image}"
    exec_color "zstd -f --rm ${new_image}"
}

function create_manifest {
    echo_color "
Step $(ctr): Populate OCI manifest with artifact $1"
    TYPE=$1
    new_image="image/$(basename ${IMAGE}).${TYPE}.zst"
    exec_color "podman manifest add ${VARIANT} --os ${OS} --arch=${ARCH} --artifact --artifact-type application/x-qemu-disk --annotation disktype=${TYPE} ${IMAGE} ${new_image}"
}

function push_manifest {
    echo_color "
Step $(ctr): Push OCI manifest and artifacts to container registry"
    exec_color "podman manifest push --all ${IMAGE}"
}

function inspect {
    echo_color "
Step $(ctr): Inpspect the OCI Manigest"
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

function clone_ai {
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

if [ "$1" == 1 ]; then
    init
    build
    oci_test
    exit
fi

if [ "$1" == 2 ]; then
    push
    demo
    rebuild
    push
    demo
    read
    create_disk_image $TYPE
    test_crun_vm
fi

if [ "$1" == 3 ]; then
    create_disk_image ami
    create_manifest $TYPE
    create_manifest ami
    push_manifest
    inspect
    clone_containerfiles
fi
if [ "$1" == 4 ]; then
    echo hello
fi
