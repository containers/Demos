#!/bin/bash

export DEFAULT_APP="chatbot"

. ../podman_helper.sh

function clone_ai {
    echo_color "

    Clone AI and explore what is available for use with the Podman Desktop AI Studio
"

    exec_color "git clone https://github.com/containers/ai-lab-recipes 2>/dev/null || (cd ai-lab-recipes; git pull origin main)"

    exec_color "podman build --build-arg MODEL_URL=https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.1-GGUF/resolve/main/mistral-7b-instruct-v0.1.Q4_K_M.gguf -t ${REGISTRY}/mymodel ai-lab-recipes/models"

    exec_color "podman push ${REGISTRY}/mymodel:1.0"

    exec_color "podman build -t ${REGISTRY}/model_server:1.0 -f ai-lab-recipes/model_servers/llamacpp_python/base/Containerfile ai-lab-recipes/model_servers/llamacpp_python/"

    exec_color "podman push ${REGISTRY}/model_server:1.0"

    exec_color "podman build -t ${REGISTRY}/$APP:1.0 -f ai-lab-recipes/recipes/natural_language_processing/${APP}/builds/Containerfile ai-lab-recipes/recipes/natural_language_processing/${APP}"

    exec_color "podman push ${REGISTRY}/${APP}:1.0"
}

function build {
    if [ -f "${XDG_RUNTIME_DIR}/containers/auth.json" ]; then
        AUTH_JSON="${XDG_RUNTIME_DIR}/containers/auth.json"
    else
        AUTH_JSON="${HOME}/.docker/config.json"
    fi

    exec_color "sudo REGISTRY_AUTH_FILE=$AUTH_JSON podman build --security-opt label=disable -v ${AUTH_JSON}:/run/containers/0/auth.json --cap-add SYS_ADMIN --from registry.redhat.io/rhel9-beta/rhel-bootc:9.4 --build-arg=SERVERIMAGE=${REGISTRY}/model_server:1.0 --build-arg=APPIMAGE=${REGISTRY}/${APP}:1.0 --build-arg=MODELIMAGE=${REGISTRY}/mymodel:1.0 --build-arg "SSHPUBKEY=$(cat ~/.ssh/mykey.pub)" -t ${REGISTRY}/${APP}-bootc:1.0 -f ai-lab-recipes/recipes/natural_language_processing/${APP}/bootc/Containerfile ai-lab-recipes/recipes/natural_language_processing/${APP}"

    exec_color "sudo REGISTRY_AUTH_FILE=$AUTH_JSON podman push ${REGISTRY}/${APP}-bootc:1.0"
}

function step_one {
	init
	login
	clone_ai
}

function step_two {
	build
	export IMAGE=${REGISTRY}/${APP}-bootc:1.0
	oci_test
}

function step_three {
	create_disk_image "--type $TYPE"
}

function step_four {
	clone_containerfiles
}

case "${1:-""}" in
    1)
	step_one
	;;
    2)
	step_two
	;;
    3)
	step_three
	;;
    4)
	step_four
	;;
    h)
	echo_color "
Users must specify specific sections to demonstrate 1-5 to run this demonstration.

    1) Clone github.com/containers/ai-lab-recipes and podman build container images off of content. Push container images to a container registry
    2) Build bootable container image with embeded AI Container images and test locally as a container. Push the bootable container image to registry
    3) Convert the OCI Image to an $TYPE and test image locally.
    4) Add cloud-init and nvidia libraries to make it easier to run your image in the cloud with Nvidia GPUs.
"
	;;
    *)
	step_one
	step_two
	step_three
	step_four
	;;

esac
