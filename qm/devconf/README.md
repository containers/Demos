# Driving Simulation and Service Monitoring

This demo is a driving simulation application that combines video playback with
real-time service status monitoring.
It leverages modern open-source projects such as
[Podman](https://github.com/containers/podman)
[Systemd](https://github.com/systemd/systemd)
[QM](https://github.com/containers/qm)
[Bluechi](https://github.com/containers/bluechi)

The application uses Pygame for video display, OpenCV for video processing
and system commands to check service statuses.

## Requirements

Install the following packages

```bash
pip install pygame opencv-python click
```

## Setup VM for Containers

First, you need to create a virtual machine (VM) to run HOST partition and
QM partitions as isolated files systems. After setting up the VM, configure
SSH access without a password. This can be achieved by generating SSH keys
on your local machine and copying the public key to the VM's `authorized_keys`
file.

## Usage

1. Ensure your driving video file is available in mp4 format.

2. The IP host must contain two partitions:
   `host`: Runs critical processes such as tires, safety,
    brakes, and cruise control.
   `QM`: Runs QM non critical services such as radio, maps, store
    and stream audio (which are isolated under /usr/lib/qm/rootfs/
    file systed with its own system).
    How to setup the QM environment? It's possible to use
    [qm setup](https://github.com/containers/qm/blob/main/demos/devconf-2024/setup)
    inside VM.

3. Run the application with the IP address of the server where the services are
running and the path to the video file:

   ```bash
     ./driving-displaying-host-qm-status
       --ip IP_VM_RUNNING_BLUECHI_AND_QM_CONTAINERS
       --port VM_SSH_PORT_FORWARD
       --video .video_car_driving.mp4
   ```

4. On a different terminal use bluechictl stop, start, restart HOST/QM services
in the NODE and QM partitions the messages popup in the video while driving
like a real agent.

You could also run load tests and check the status in video indicators
