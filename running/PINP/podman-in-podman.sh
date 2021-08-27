#!/usr/bin/env sh

read -p "# rootful podman in rootful podman with --privileged"
read -p "--> sudo podman run --privileged quay.io/podman/stable id && podman run ubi8-minimal echo hello"
echo ""
sudo podman run --privileged quay.io/podman/stable id && podman run ubi8-minimal echo hello
echo ""

read -p "# rootless podman in rootful podman with --privileged"
read -p "--> sudo podman run --privileged --user podman quay.io/podman/stable id && podman run ubi8-minimal echo hello"
echo ""
sudo podman run --privileged --user podman quay.io/podman/stable id && podman run ubi8-minimal echo hello
echo ""

read -p "# rootful podman in rootless podman with --privileged"
read -p "--> podman run --privileged quay.io/podman/stable id && podman run ubi8-minimal echo hello"
echo ""
podman run --privileged quay.io/podman/stable id && podman run ubi8-minimal echo hello
echo ""

read -p "# rootless podman in rootless podman with --privileged"
read -p "--> podman run --privileged --user podman quay.io/podman/stable id && podman run ubi8-minimal echo hello"
echo ""
sudo podman run --privileged --user podman quay.io/podman/stable id && podman run ubi8-minimal echo hello
echo ""

read -p "# rootful podman in rootful podman without --privileged"
read -p "--> sudo podman run --cap-add=sys_admin,mknod --device=/dev/fuse --security-opt label=disable quay.io/podman/stable id && podman run ubi8-minimal echo hello"
echo ""
sudo podman run --cap-add=sys_admin,mknod --device=/dev/fuse --security-opt label=disable quay.io/podman/stable id && podman run ubi8-minimal echo hello
echo ""

read -p "# rootless podman in rootful podman without --privileged"
read -p "--> sudo podman run --user podman --security-opt label=disable --security-opt unmask=ALL --device /dev/fuse -ti quay.io/podman/stable id && podman run ubi8-minimal echo hello"
echo ""
sudo podman run --user podman --security-opt label=disable --security-opt unmask=ALL --device /dev/fuse -ti quay.io/podman/stable id && podman run ubi8-minimal echo hello
echo ""

read -p "# rootless podman in rootless podman without --privileged"
read -p "--> podman run --security-opt label=disable --user podman --device /dev/fuse quay.io/podman/stable id && podman run ubi8-minimal echo hello"
echo ""
podman run --security-opt label=disable --user podman --device /dev/fuse quay.io/podman/stable id && podman run ubi8-minimal echo hello
echo ""