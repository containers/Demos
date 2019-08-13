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

    podman image exists quay.io/sallyom/hello-openshift:test
    rc=$?; if [[ $rc != 0 ]]; then podman pull quay.io/sallyom/hello-openshift:test; fi
    podman image exists quay.io/sallyom/hello-openshift:test
    mkdir -p /tmp/hello-openshift-container
}

cleanPodmanContainers() {
    podman stop -a -t 1
    podman rm -fa
}

cleanKube() {
    oc delete pod --all
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
runCommand "podman container runlabel run quay.io/sallyom/hello-openshift:test"
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

sendMessage "Check the IP for the hello pod"
runCommand "oc describe pod hello"



#IP=`oc describe pod hello | grep "Node:" | cut -f2 --delimiter /`
#PORT=`oc get svc --no-headers=true demoweb  | awk '{print $5}' | cut -f 2 --delimiter : | sed -e "s/\/TCP//g"`

#sendMessage "Connect web browser to http://$IP:$PORT"

sendMessageWait "Next keystroke cleans up podman containers and OpenShift"
cleanPodmanContainers
cleanKube
