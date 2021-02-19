#!/usr/bin/bash
BOLD="$(tput bold)"
RESET="$(tput sgr0)"

cmd () {
	echo ""
	read -p " \$ $1"
	$1
}

read -p "${BOLD}Podman auto-update demo${RESET}"
echo ""
read -p " * Auto updates make use of the tight integration of Podman with systemd"
read -p " * Updates can be triggered via \`podman auto-update\`"
read -p " * Or via a customizable systemd timer/unit pair"
read -p " * Target use-case: edge"

echo ""
read -p " ... let's have a look at the workflow!"

echo ""
read -p "${BOLD}Run a local registry, copy an image to it, and create a container.${RESET}"

podman rm -af > /dev/null

cmd 'podman run -d -p 5000:5000 registry:2'
cmd 'skopeo copy docker://alpine:3.1 docker://localhost:5000/alpine:demo'
cmd 'podman create --replace --name demo --label "io.containers.autoupdate=image" localhost:5000/alpine:demo top'

echo ""
read -p "${BOLD} * Notice the --label \"io.containers.autoupdate=image\" ??? ${RESET}"
read -p "${BOLD} * Now, let's generate a systemd unit for the container and run it ${RESET}"

cmd 'podman generate systemd --name --new --files demo'
podman rm -f demo > /dev/null
cmd "cp ./container-demo.service $HOME/.config/systemd/user/"
systemctl --user stop container-demo.service > /dev/null
cmd 'systemctl --user daemon-reload'
cmd 'systemctl --user start container-demo.service'

echo ""
read -p "${BOLD} * Let's have a look at the service${RESET}"
read -p "${BOLD} * Remember the \"Main PID\"${RESET}"

cmd "systemctl --user status container-demo.service"
cmd "podman auto-update"

echo ""
read -p "${BOLD} * No new image, no update :)${RESET}"
read -p "${BOLD} * So let's update the image, and re-run${RESET}"

cmd 'skopeo copy docker://alpine:latest docker://localhost:5000/alpine:demo'
cmd "podman auto-update"
cmd "systemctl --user status container-demo.service"

echo ""
read -p "${BOLD} * The \"Main PID\" has changed${RESET}"
read -p "${BOLD} * Podman has restarted the service once the updated image was pulled${RESET}"
read -p "${BOLD} ----- END OF DEMO -----${RESET}"
