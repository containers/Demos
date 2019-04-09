#!/bin/sh

# podman_images.sh demo script.
# This script will demonstrate at an introductory level
# the use of the podman images command.
# Podman must be installed prior to running this script.

 
# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

read_color() {
    read -p "${bold}$1${reset}"
}

echo_color() {
    echo "${cyan}$1${reset}"
}

setup() {
    rpm -q podman >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the podman package to be installed
	exit 1
    fi
    clear
}

intro() {
    echo_color "\`podman images\` Demo"
    echo
    echo_color "Available at https://github.com/containers/Demos/podman_cli/podman_images.sh"
    echo
}

version() {
   
    echo_color "First check the Podman version"
    echo
    read_color "podman version"
    echo
    podman version
    echo

    echo
    read -p "Enter to continue"
    clear
}

podman_pull_images() {
    echo_color "Let's pull our very first container image"
    echo
    read_color "podman pull alpine"
    podman pull alpine

    echo
    echo_color "Let's look at the image"
    echo
    read_color "podman images"
    podman images

    echo
    echo_color "Let's pull a busybox and nginx container image"
    echo
    read_color "podman pull busybox"
    podman pull busybox 
    echo
    read_color "podman pull nginx:latest"
    podman pull nginx:latest

    echo
    echo_color "Let's look at the images"
    echo
    read_color "podman images"
    podman images

    echo
    read -p "Enter to continue"
    clear
}


podman_from_dockerfile() {

    /bin/cat <<- "EOF" > ./Dockerfile.hello
FROM alpine
RUN apk add python3
ADD HelloFromContainer.py /home
WORKDIR HOME
CMD ["python3","/home/HelloFromContainer.py"]
EOF
    /bin/cat <<- "EOF" > ./HelloFromContainer.py
#!/usr/bin/env python3
#
import sys
def main(argv):
    for i in range(0,10):
        print ("Hello World from Container Land! Message # [%d]" % i)
if __name__ == "__main__":
    main(sys.argv[1:])
EOF

    echo
    echo_color "Create an image from a Dockerfile and run the container"
    echo_color "Let's first look at our Dockerfile"
    echo
    read_color "cat ./Dockerfile.hello"
    cat ./Dockerfile.hello

    echo
    echo_color "Let's look at our HelloFromContainer.py"
    echo
    read_color "cat ./HelloFromContainer.py"
    cat ./HelloFromContainer.py

    echo
    echo_color "Create the \"hello\" image from the Dockerfile"
    echo
    read_color "podman build -t hello -f ./Dockerfile.hello ."
    podman build -t hello -f ./Dockerfile.hello .

    echo
    echo_color "Run the container just to prove the container image is viable"
    echo
    read_color "podman run --name helloctr hello"
    podman run --name helloctr hello

    echo
    echo_color "Commit the helloctr to make a personal image named myhello"
    echo
    read_color "podman commit -q --author \"John Smith\" helloctr myhello"
    podman commit -q --author "John Smith" helloctr myhello

    echo
    echo_color "Let's look at the images"
    echo
    read_color "podman images"
    podman images
}

podman_images() {
    echo
    echo_color "Let's look at what else the images command can do"
    echo
    echo_color "Show only the image ID's"
    echo
    read_color "podman images -q"
    podman images -q

    echo
    echo_color "Show the busybox image"
    echo
    read_color "podman images busybox"
    podman images busybox

    echo
    echo_color "Show the images without a table heading"
    echo
    read_color "podman images --noheading"
    podman images --noheading

    echo
    echo_color "Show the images without truncating any fields"
    echo
    read_color "podman images --no-trunc"
    podman images --no-trunc

    echo
    echo_color "Show the image digests"
    echo
    read_color "podman images --digests"
    podman images --digests

    echo
    echo_color "Show only the ID, Repository and Tag fields"
    echo
    read_color "podman images --format \"table {{.ID}} {{.Repository}} {{.Tag}}\""
    podman images --format "table {{.ID}} {{.Repository}} {{.Tag}}"

    echo
    echo_color "Show in json format"
    echo
    read_color "podman images --format json"
    podman images --format json

    echo
    echo_color "Show only the alpine image using a filter"
    echo
    read_color "podman images --filter reference=alpine"
    podman images --filter reference=alpine

    echo
    echo_color "Show the images sorted by size"
    echo
    read_color "podman images --sort size"
    podman images --sort size


    echo
    read -p "Enter to continue"
    clear
}

clean_images_and_containers() {

    read_color "podman rm -a"
    podman rm -a
    echo
    read_color "podman rmi -a -f"
    podman rmi -a -f

    echo
    read -p "Enter to continue"
    clear
}

clean_temp_files() {

    rm -rf Dockerfile.hello HelloFromContainer.py
}

setup

intro

version

podman_pull_images

podman_from_dockerfile

podman_images

clean_images_and_containers

clean_temp_files

read -p "End of Demo!!!"
echo
echo "Thank you!"
