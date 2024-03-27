#!/bin/bash

DEFAULT_APP="inference"

. ../podman_helper.sh

function build {
    echo_color "
Build bootable OCI Image"

    FROM=""
    exec_color "cat $APP/Containerfile"

    exec_color "podman manifest exists ${IMAGE} && podman manifest rm ${IMAGE} || podman rmi --force ${IMAGE}"

    exec_color "podman build --security-opt label=disable -v $HOME/.local/share/containers:/tmp/containers -v $XDG_RUNTIME_DIR/containers/auth.json:/run/containers/0/auth.json:z --no-cache --cap-add SYS_ADMIN --build-arg TAG=1.0 --build-arg \"SSHPUBKEY=$(cat $HOME/.ssh/id_rsa.pub)\"  --build-arg=\"REGISTRY=$REGISTRY\" --arch=${ARCH} $FROM--manifest ${IMAGE} $APP/"
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
	create_disk_image "--type $TYPE"
	;;
    5)
	clone_containerfiles
	;;
    *)
	echo_color "
Users must specify specific sections to demonstrate 1-5 to run this demonstration.

    1) Clone github.com/containers/ai-lab-recipes and podman build container images off of content. Push container images to a container registry
    2) Build bootable container image with embeded AI Container images and test locally as a container.
    3) Push the bootable container image to registry
    4) Convert the OCI Image to an $TYPE and test image locally.
    5) Add cloud-init and nvidia libraries to make it easier to run your image in the cloud with Nvidia GPUs.
"
	;;
esac
