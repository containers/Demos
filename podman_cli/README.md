# Demos - podman_cliG

## Podman Command Demo Scripts

This directory is the home of the Demo scripts for the Podman CLI commands.
It is expected that these scripts will be used for demonstration purposes, and most
specifically as links on the [commands.md](https://github.com/containers/libpod/blob/master/commands.md)
file in the [libpod](https://github.com/containers/libpod) GitHub project.  The scripts in this directory
should be run and recorded using [asciinema](https://asciinema.org/).  The casts from
that recording should be captured and stored on the [podman.io](https://github.com/containers/podman.io) site under the [asciinema](https://github.com/containers/podman.io/tree/master/asciinema)
top level directory.  This page documents how the casts should be recorded and the
files that need to be created or modified to display them.

### Script creation

Create a script to be put into the [containers/Demos](https://github.com/containers/Demos) project in the containers/Demos/podman_cli directory.  Name it `podman_{command}.sh`.  For example `podman_images.sh` for the `podman images` command.  Make sure it shows as many features of the command as possible and is well documented.  Use the podman_images.sh file in this directory as a base example.  The script should targeted for use by someone with little Podman knowledge.

Once you are satisfied with your script, do a standard Git add/commit/push cycle to create a PR for the script.

### VM setup 
 
Create a new Fedora Virtual Machine (vm) and `dnf -y install asciinema` to install asciinema.
Install the latest Podman with `dnf -y install podman --enablerepo updates-testing`.

Login to the vm with a 24 rows X 132 columns terminal as a non-root user, copy your script there and ensure that you can run the script.

### Demo recording

Before running the script, start asciinema with `asciinema rec`.  Then run your script making sure to
pause long enough for each command so that a first time viewer can read all of the output.

When your script has completed, turn off the recording with `<ctrl>d` `<ctrl>c`.  Then copy the /tmp/*.cast file that was created by the recording to ./podman_{command}.cast

### Store cast in podman.io

Create a PR in https://github.com/containers/podman.io

In the asciinema directory, create a directory under the podman directory that's the same name as the command you're demoing.  Copy your podman_{command}.cast file to this directory.  For instance `asciinema/podman/images/podman_images.cast` for the `podman images` recording.

Copy the index.html from asciinema/podman/images/index.html to your new directory.  Update the index.html changing the name of the file inside of index.html to the podman_{command}.cast file that you recorded.

Do a standard Git add/commit/push cycle to create a PR for these changes.

### Update commands.md in libpod

After the PR's for the script and recording are merged, create a PR in [libpod](https://github.com/containers/libpod) on GitHub to update https://github.com/containers/libpod/commands.md, adding links to the script and the podman.io asciinema locations for the command that you created the script and recording of.
