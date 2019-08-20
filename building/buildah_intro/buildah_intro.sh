#!/usr/bin/env sh

# buildah_intro.sh demo script.
# This script will demonstrate at an introductory level
# for Buildah basic concepts and uses.  Also requires
# the Docker and Podman packages to be installed.

 
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
    rpm -q buildah >/dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the buildah package to be installed
	exit 1
    fi
    command -v docker > /dev/null
    if [[ $? != 0 ]]; then
	echo $0 requires the docker package to be installed
	exit 1
    fi
    sudo systemctl restart docker
    clear
}

intro() {
    read -p "Buildah Demos!"
    echo
}

version() {
    # Buildah version inside a container
    echo_color "Check the Buildah version"
    echo
    read_color "buildah version"
    echo
    buildah version
    echo

    # Buildah info inside a container
    echo
    echo_color "Check the Buildah info"
    echo
    read_color "buildah info"
    echo
    buildah info

    echo
    read -p "Enter to continue"
    clear
}

buildah_first_image() {
    echo_color "Let's create our very first container image"
    echo
    read_color "sudo buildah pull alpine"
    sudo buildah pull alpine

    echo
    echo_color "Let's look at the image"
    echo
    read_color "sudo buildah images"
    sudo buildah images

    echo
    echo_color "Create a container from the image"
    echo
    read_color "sudo buildah from docker.io/library/alpine"
    sudo buildah from docker.io/library/alpine

    echo
    echo_color "Look at the container"
    echo
    read_color "sudo buildah containers"
    sudo buildah containers

    echo
    read -p "Enter to continue"
    clear
}

buildah_using_from_scratch() {

    echo_color "Create an empty image from 'scratch'"
    echo
    read_color "newcontainer=\$(sudo buildah from scratch)"
    newcontainer=$(sudo buildah from scratch)
    echo

    echo
    echo_color "Now mount the container saving the mount point"
    echo
    read_color "scratchmnt=\$(sudo buildah mount \$newcontainer)"
    scratchmnt=$(sudo buildah mount $newcontainer)

    echo
    echo_color "Show the location of the mount point"
    echo
    read_color "echo \$scratchmnt"
    echo $scratchmnt

    echo
    echo_color "Show the contents of the mountpoint"
    echo
    read_color "sudo ls \$scratchmnt"
    sudo ls $scratchmnt
    read -p "Enter to continue"

    echo
    echo_color "Install Fedora 29 bash and coreutils into the container from the host."
    echo_color "Only bash and coreutils packages and their dependencies will be installed."
    echo
    read_color "sudo dnf install --installroot \$scratchmnt --release 29 bash coreutils --setopt install_weak_deps=false -y"
    sudo dnf install --installroot $scratchmnt --release 29 bash coreutils --setopt install_weak_deps=false -y


    echo
    echo_color "Show the contents of the mountpoint post install"
    echo
    read_color "sudo ls \$scratchmnt"
    sudo ls $scratchmnt

    echo
    echo_color "Show /usr/local/bin inside of the container"
    echo
    read_color "sudo buildah run \$newcontainer -- ls -alF /usr/local/bin"
    sudo buildah run $newcontainer -- ls -alF /usr/local/bin

    /bin/cat > ./runecho.sh <<- "EOF" 
#!/usr/bin/env bash
for i in {1..9};
do
    echo "This is a new container from buildahdemo [" $i "]"
done
EOF
    echo
    echo_color "Display contents of runecho.sh"
    echo
    read_color "cat ./runecho.sh"
    cat ./runecho.sh
    chmod +x ./runecho.sh

    echo
    echo_color "Copy the script into the container"
    echo
    read_color "sudo buildah copy \$newcontainer ./runecho.sh /usr/local/bin"
    sudo buildah copy $newcontainer ./runecho.sh /usr/local/bin

    echo
    echo_color "Set the cmd of the container to the script"
    echo
    read_color "sudo buildah config --cmd /usr/local/bin/runecho.sh \$newcontainer"
    sudo buildah config --cmd /usr/local/bin/runecho.sh $newcontainer

    echo
    echo_color "Let's run the container which will run the script"
    echo
    read_color "sudo buildah run $newcontainer /usr/local/bin/runecho.sh"
    sudo buildah run $newcontainer /usr/local/bin/runecho.sh

    echo
    echo_color "Configure the container added created-by then author information"
    echo
    read_color "sudo buildah config --created-by \"buildahdemo\"  \$newcontainer"
    sudo buildah config --created-by "buildahdemo"  $newcontainer

    echo
    echo
    read_color "sudo buildah config --author \"buildahdemo\" --label name=fedora29-bashecho \$newcontainer"
    sudo buildah config --author "buildahdemo at redhat.com" --label name=fedora29-bashecho $newcontainer

    echo
    echo_color "Let's inspect the container looking for our new configs"
    echo
    read_color "sudo buildah inspect \$newcontainer"
    sudo buildah inspect $newcontainer

    echo
    echo_color "Now unmount the container as we're done adding stuff to it"
    echo
    read_color "sudo buildah unmount \$newcontainer"
    sudo buildah unmount $newcontainer

    echo
    echo_color "Commit the image that we've created"
    echo
    read_color "sudo buildah commit \$newcontainer fedora-bashecho"
    sudo buildah commit $newcontainer fedora-bashecho

    echo
    echo_color "Check for our image"
    echo
    read_color "sudo buildah images"
    sudo buildah images

    echo
    echo_color "Remove the container"
    echo
    read_color "sudo buildah rm \$newcontainer"
    sudo buildah rm $newcontainer

    echo
    read -p "Enter to continue"
    clear
}

run_image_in_docker() {
    systemctl restart docker

    echo
    echo_color "Push our image to the Docker daemon"
    echo
    read_color "sudo buildah push fedora-bashecho docker-daemon:fedora-bashecho:latest"
    sudo buildah push fedora-bashecho docker-daemon:fedora-bashecho:latest

    echo
    echo_color "Show our image under Docker"
    echo
    read_color "sudo docker images"
    sudo docker images

    echo
    echo_color "Run our image under Docker"
    echo
    read_color "sudo docker run fedora-bashecho"
    sudo docker run fedora-bashecho

    echo
    read -p "Enter to continue"
    clear
}

buildah_from_dockerfile() {

    /bin/cat <<- "EOF" > ./Dockerfile.hello
FROM alpine
RUN apk add python3
ADD HelloFromContainer.py /home
WORKDIR HOME
CMD ["python3","/home/HelloFromContainer.py"]
EOF
    echo
    echo_color "Create image from a Dockerfile and run the container"
    echo_color "Let's look at our Dockerfile"
    echo
    read_color "cat ./Dockerfile.hello"
    cat ./Dockerfile.hello

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
    echo_color "Let's look at our HelloFromContainer.py"
    echo
    read_color "cat ./HelloFromContainer.py"
    cat ./HelloFromContainer.py

    echo
    echo_color "Create the \"hello\" image from the Dockerfile"
    echo
    read_color "sudo buildah bud -t hello -f ./Dockerfile.hello ."
    sudo buildah bud -t hello -f ./Dockerfile.hello .

    echo
    echo_color "Create the container from the image"
    echo
    read_color "sudo buildah from hello"
    sudo buildah from hello

    echo
    echo_color "Run the container"
    echo
    read_color "sudo buildah run hello-working-container python3 /home/HelloFromContainer.py"
    sudo buildah run hello-working-container python3 /home/HelloFromContainer.py

    echo
    echo_color "Now a quick advertisement from Podman."
    echo_color "Let's run the container using Podman."
    echo
    read_color "sudo podman run hello"
    sudo podman run hello


    echo
    read -p "Enter to continue"
    clear
}

buildah_from_dockerfile_rootless() {

    echo
    echo_color "Now we are going to run buildah rootless"
    echo
    echo_color "Create image from a Dockerfile and run the container"
    echo_color "Let's look at our Dockerfile"
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
    read_color "buildah bud -t hello -f ./Dockerfile.hello ."
    buildah bud -t hello -f ./Dockerfile.hello .

    echo
    echo_color "Create the container from the image"
    echo
    read_color "buildah from hello"
    buildah from hello

    echo
    echo_color "Run the container"
    echo
    read_color "buildah run hello-working-container python3 /home/HelloFromContainer.py"
    buildah run hello-working-container python3 /home/HelloFromContainer.py

    echo
    echo_color "Now a quick advertisement from Podman."
    echo_color "Let's run the container using Podman."
    echo
    read_color "podman run hello"
    podman run hello


    echo
    read -p "Enter to continue"
    clear
}

clean_images_and_containers() {

    read_color "sudo buildah rm -a"
    sudo buildah rm -a
    echo
    read_color "sudo buildah rmi -a -f"
    sudo buildah rmi -a -f

    echo
    read -p "Enter to continue"
    clear
}

clean_temp_files() {

    rm -rf Dockerfile.hello runecho.sh HelloFromContainer.py
}

setup

intro

version

buildah_first_image

buildah_using_from_scratch

run_image_in_docker

buildah_from_dockerfile

clean_images_and_containers

buildah_from_dockerfile_rootless

clean_images_and_containers

clean_temp_files

read -p "End of Demo!!!"
echo
echo "Thank you!"
