#!/bin/bash

export DEFAULT_APP="lamp"

source ../podman_helper.sh

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

    exec_color "podman manifest exists ${IMAGE} && podman manifest rm ${IMAGE} || podman rmi --force ${IMAGE}"
    exec_color "podman build --build-arg=\"SSHPUBKEY=$(cat "${HOME}/.ssh/id_rsa.pub")\" --arch=${ARCH} $FROM--manifest ${IMAGE} $APP/"
}

function test_crun_vm {
    if ! command -v crun-vm; then
        sudo bash -c "dnf -y install crun-vm"
    fi
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

case "${1:-""}" in
    1)
	init
	build
	oci_test
	;;
    2)
	login ${REGISTRY}
	push_manifest
	demo
	;;
    3)
	create_disk_image "--type ${TYPE} --type ami"
	rename "${TYPE}"
	rename ami
	test_crun_vm
	;;
    4)
	create_manifest "${TYPE}"
	create_manifest ami
	push_manifest
	inspect
	;;
    5)
	clone_containerfiles
	;;
    *)
	echo_color "
Users must specify specific sections to demonstrate 1-5 to run this demonstration.

    1) Build a bootable OCI Container image and then testing it as an OCI container image
    2) Push the container image to a container registry, demonstrate converting a running
       AMI to the bootable container image.
    3) Convert the OCI Image to an $TYPE and test the image locally using crun-vm to make
       sure the image works proplery.
    4) Convert the OCI Image to an AMI disk image, add the $TYPE and AMI diskimage to the
       OCI image manifest and finally push the OCI Manifest and the disk images to a
       container registry. Finally inspect the manifest to see how tools could pull down
       specific images.
    5) Add cloud-init and nvidia libraries to make it easier to run your image in the cloud
       with Nvidia GPUs.
"

	;;
esac
