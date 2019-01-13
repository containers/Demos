#!/bin/bash


setup () {
    # Verify podman exists
    if ! hash podman 2>/dev/null; then
        echo "Unable to find the podman commmand"
        exit 1
    fi

    # Verify kubectl exists
    if ! hash kubectl 2>/dev/null; then
        echo "Unable to find the kubectl commmand"
        exit 1
    fi
    sudo podman image exists quay.io/baude/demodb:latest
    rc=$?; if [[ $rc != 0 ]]; then sudo podman pull quay.io/baude/demodb:latest; fi
    sudo podman image exists quay.io/baude/demogen:latest
    rc=$?; if [[ $rc != 0 ]]; then sudo podman pull quay.io/baude/demogen:latest; fi
    sudo podman image exists quay.io/baude/demoweb:latest
    rc=$?; if [[ $rc != 0 ]]; then sudo podman pull quay.io/baude/demoweb:latest; fi

    mkdir -p /tmp/kube-container
    mkdir -p /tmp/kube-pod
}

cleanPodmanContainers() {
    sudo podman stop -a -t 1
    sudo podman rm -fa
}

cleanKube() {
    sudo kubectl delete svc demoweb-libpod
    sudo kubectl delete pod --all
}

tailContainer () {
    read -p "$ sudo podman logs -lf"
    while [ 0 -eq 0 ]
    do
        trap break INT
        sudo podman logs -lf
    done
    echo ""
}

watchPods() {
    read -p "$ sudo kubectl get pods --watch "
    while [ 0 -eq 0 ]
    do
        trap break INT
        sudo kubectl get pods --watch
    done
    echo ""
}

runCommand() {
    echo ""
    read -p "$ $1"
    $1
    echo ""
}

runPipeCommand() {
    echo ""
    read -p "$ $1 > $2"
    $1 > $2
    echo ""
}

sendMessage() {
    echo ""
    echo "$1"
    echo ""
}

sendMessageWait() {
    echo ""
    read -p "$1"
    echo ""
}

setup
clear


##
## Create demodb as a container
##
sendMessage "Use runlabel create components as containers only"
sendMessage "Create the database container"
runCommand "sudo podman container runlabel run quay.io/baude/demodb:latest"
sendMessage "Check the logs to make sure the database is running"
tailContainer


##
## Create demogen as a container
##
sendMessage "Create the workload generator"
runCommand "sudo podman container runlabel run quay.io/baude/demogen:latest"
sendMessage "Check the logs to make sure the generator is running"
tailContainer

##
## Create demoweb as a container
##
sendMessage "Create the web-client"
runCommand "sudo podman container runlabel run quay.io/baude/demoweb:latest"
sendMessage "Check the logs to make sure the generator is running"
tailContainer



##
## Show our containers
##
runCommand "sudo podman ps"

##
## Create YAML for containers
##
sendMessage "Podman can generate YAML based on a container"
runCommand "sudo podman generate kube --help"

sendMessage "Generate Kubernetes YAML for 'demodb'"
runCommand "sudo podman generate kube demodb"

sendMessage "Run for each container and pipe to a file"
sendMessage "Generate Kubernetes YAML for 'demodb'"
runPipeCommand "sudo podman generate kube demodb" "/tmp/kube-container/demodb.yaml"
sendMessage "Generate Kubernetes YAML for 'demogen'"
runPipeCommand "sudo podman generate kube demogen" "/tmp/kube-container/demogen.yaml"
sendMessage "Generate Kubernetes YAML and a service for 'demoweb'"
runPipeCommand "sudo podman generate kube -s demoweb" "/tmp/kube-container/demoweb.yaml"


##
## Create Components in Kube
##
sendMessage "Start creating the components in minkube"
sendMessage "Create demodb"
runCommand "sudo kubectl create -f /tmp/kube-container/demodb.yaml"
watchPods

sendMessage "Create demogen"
runCommand "sudo kubectl create -f /tmp/kube-container/demogen.yaml"
watchPods

sendMessage "Create demoweb"
runCommand "sudo kubectl create -f /tmp/kube-container/demoweb.yaml"
watchPods

sendMessage "Check demoweb service"
runCommand "sudo kubectl get svc"

sendMessage "Check the IP for the demoweb pod"
runCommand "sudo kubectl describe pod demoweb-libpod"



IP=`sudo kubectl describe pod demoweb-libpod | grep "Node:" | cut -f2 --delimiter /`
PORT=`sudo kubectl get svc --no-headers=true demoweb-libpod  | awk '{print $5}' | cut -f 2 --delimiter : | sed -e "s/\/TCP//g"`

sendMessage "Connect web browser to http://$IP:$PORT"

sendMessageWait "Next keystroke cleans up podman containers and kube"
cleanPodmanContainers
cleanKube
