#!/bin/bash

trap 'exit 0' INT

# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
blue=$(tput setaf 4)
reset=$(tput sgr0)

read_color() {
    read -p "${bold}$1${reset}"
}

echo_color() {
    echo "${blue}$1${reset}"
}

setup () {
    # Verify podman exists
    if ! hash podman 2>/dev/null; then
	echo "Unable to find the podman commmand"
	exit 1
    fi

    # Verify oc exists
    if ! hash oc 2>/dev/null; then
	echo "Unable to find the oc commmand"
	exit 1
    fi
    sudo systemctl restart crio
    rc=$?; if [[ $rc != 0 ]]; then
	echo "Unable to start the crio daemon"
	exit 1
    fi

    podman image exists quay.io/sallyom/hello-openshift:new
    rc=$?; if [[ $rc != 0 ]]; then podman pull quay.io/sallyom/hello-openshift:new; fi
    podman image exists quay.io/sallyom/hello-openshift:new
    mkdir -p /tmp/hello-openshift-container
    oc new-project hello-openshift
}

cleanPodmanContainers() {
    podman stop -a -t 1
    podman rm -fa
}

cleanKube() {
    oc delete project hello-openshift --force --grace-period=0
}

tailContainer () {
    echo_color "Execute ^c to exit the log"
    echo ""
    read_color "$ podman logs -lf"
    while [ 0 -eq 0 ]
    do
	trap break INT
	podman logs -lf
    done
    echo ""
    trap 'exit 0' INT
    clear
}

watchPods() {
    read_color "$ oc get pods --watch "
    while [ 0 -eq 0 ]
    do
	trap break INT
	oc get pods --watch
    done
    echo ""
    trap 'exit 0' INT
}

runCommand() {
    echo ""
    read_color "$ $1"
    $1
    echo ""
    read -p "Continue"
    clear
}

runPipeCommand() {
    echo ""
    read_color "$ $1 > $2"
    $1 > $2
    echo ""
    read -p "Continue"
    clear
}

sendMessage() {
    echo ""
    echo_color "$1"
    echo ""
}

sendMessageWait() {
    echo ""
    read_color "$1"
    echo ""
}

setup
clear


##
## Create hello-openshift as a container
##
sendMessage "Use runlabel create components as containers only"
sendMessage "Create the hello-openshift container"
sendMessage "Dockerfile with runlabels:"
cat <<_EOF
FROM alpine
COPY bin/hello-openshift /hello-openshift
EXPOSE 8080 8888
LABEL RUN="podman run --name hello -p 8080:8080 -dt IMAGE"
LABEL POD="podman run new:hello -dt IMAGE"
ENTRYPOINT ["/hello-openshift"]
_EOF

runCommand "podman container runlabel run quay.io/sallyom/hello-openshift:new"
sendMessage "Check the logs to make sure the container is running"
tailContainer

##
## Show our containers
##
runCommand "podman ps"

##
## Create YAML for containers
##
sendMessage "Podman can generate YAML based on a container"
runCommand "podman generate kube --help"

sendMessage "Generate Kubernetes YAML for 'hello'"
runCommand "podman generate kube hello"

sendMessage "Run for each container and pipe to a file"
sendMessage "Generate Kubernetes YAML for 'hello'"
runPipeCommand "podman generate kube hello" "/tmp/hello-openshift-container/hello.yaml"

##
## Create Components in Kube
##
sendMessage "Start creating the components in OpenShift"
sendMessage "Create openshift-hello"
runCommand "oc create -f /tmp/hello-openshift-container/hello.yaml"
watchPods

sendMessage "Describe the hello pod"
runCommand "oc describe pod hello"

sendMessage "expose the pod to create a service"
runCommand "oc expose pod hello"

sendMessage "expose the service to create a route"
runCommand "oc expose svc hello"

sendMessage "curl the route"
runCommand "oc get route hello"
route=$(oc get route hello | awk '{print $2}' | grep hello)
runCommand "curl ${route}"

sendMessageWait "Next keystroke cleans up podman containers and OpenShift"
cleanPodmanContainers
cleanKube