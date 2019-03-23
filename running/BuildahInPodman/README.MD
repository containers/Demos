# BuildahInPodman

This script demonstrates running a Buildah container inside
of a Podman container without needing root in the Buildah
container.  Buildah will be installed in both the Podman
and the Buildah containers.

You need to execute the building_ctr_wo_root.sh script in
this directory.  The script will install the latest versions
of Podman and Buildah using yum.
