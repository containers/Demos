# ReplacingDocker

This script demonstrates new security features in podman
You need to execute the podman.sh script in this directory.
* Running ping without NET_RAW
* Using oci-seccomp-bpf-hook to generate seccomp.json files
* Using containers.conf
* Using Udica
* Using Capability lists specified inside of a container image

The script will create the buildah-ctr if it does not exist.
