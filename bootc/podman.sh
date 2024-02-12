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


DEFAULT_APP="lamp"
DEFAULT_IMAGE="quay.io/rhatdan/$DEFAULT_APP"
DEFAULT_TYPE="qcow2"
DEFAULT_ARCH=$(uname -m)
DEFAULT_VARIANT=""
DEFAULT_OS=$(uname)
DEFAULT_OS=${OS,,}


OPTSTRING=":a:i:o:v:A:"

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    i)
      IMAGE="${OPTARG}"
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
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done

[ -n "$IMAGE" ] || IMAGE=$DEFAULT_IMAGE
[ -n "$APP" ] || APP=$DEFAULT_APP
[ -n "$TYPE" ] || TYPE=$DEFAULT_TYPE
[ -n "$ARCH" ] || ARCH=$DEFAULT_ARCH
VARIANT=$VARIANT
[ -n "$OS" ] || OS=$DEFAULT_OS

clear
exec_color "podman login $IMAGE"
if [ $APP == "machine" ]; then
   podman rmi --force --ignore localhost/fcos
   exec_color "cat $APP/Containerfile.fcos"
   exec_color "podman build --arch ${ARCH} --manifest localhost/fcos -f $APP/Containerfile.fcos $APP/"
   FROM="--from localhost/fcos"
fi
exec_color "cat $APP/Containerfile"
exec_color "podman manifest rm ${IMAGE}"
exec_color "podman build --arch=${ARCH} $FROM --manifest ${IMAGE} $APP/"
exec_color "podman run --pull=never --arch=${ARCH} --rm -ti ${IMAGE} sh"
clear
exec_color "podman manifest push --all ${IMAGE}"
exec_color "sudo REGISTRY_AUTH_FILE=$XDG_RUNTIME_DIR/containers/auth.json podman run --rm -it --platform=${OS}/${ARCH} --privileged -v .:/output --pull newer quay.io/centos-bootc/bootc-image-builder --type ami --type qcow2 ${IMAGE}:latest"
exec_color "sudo chown -R $UID:$UID ."
exec_color "mv ${TYPE}/disk.${TYPE} ${TYPE}/$(basename ${IMAGE}).${TYPE}"
exec_color "podman manifest add ${VARIANT} --os ${OS} --arch=${ARCH} --artifact --artifact-type application/x-qemu-disk --annotation disktype=${TYPE} ${IMAGE} ${TYPE}/$(basename ${IMAGE}).${TYPE}"
TYPE=ami
exec_color "sudo podman run --rm -it --platform=${OS}/${ARCH} --privileged -v .:/output --pull newer quay.io/centos-bootc/bootc-image-builder --type ${TYPE} ${IMAGE}:latest"
exec_color "sudo chown -R $UID:$UID ."
exec_color "mv ${TYPE}/disk.${TYPE} ${TYPE}/$(basename ${IMAGE}).${TYPE}"
exec_color "podman manifest add ${VARIANT} --os ${OS} --arch=${ARCH} --artifact --artifact-type application/x-qemu-disk --annotation disktype=${TYPE} ${IMAGE} ${TYPE}/$(basename ${IMAGE}).${TYPE}"
exec_color "podman manifest push --all ${IMAGE}"
exec_color "skopeo inspect --raw ${IMAGE}"
