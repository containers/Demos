package demo

import (
	"github.com/urfave/cli"
)

func EnsureInfoLogLevel() {
	Ensure(
		`sudo sed -i -E 's/(log_level = )(.*)/\1"info"/' /etc/crio/crio.conf`,
		"sudo kill -HUP $(pgrep crio)",
	)
}

func Setup(ctx *cli.Context) error {
	Ensure(
		// Set log_level to debug
		`sudo sed -i -E 's/(log_level = )(.*)/\1"debug"/' /etc/crio/crio.conf`,
		"sudo kill -HUP $(pgrep crio)",

		// Remove all events
		"kubectl delete events --all",

		// Remove dead pods
		"sudo crictl rmp -f $(sudo crictl pods -s NotReady -q)",
	)
	return Cleanup(ctx)
}

func Cleanup(ctx *cli.Context) error {
	Ensure(
		"sudo pkill kubectl",
		"kubectl delete pod nginx alpine --now",
		"kubectl delete deploy nginx --now",
		"sudo crictl rmi hello-world nginx quay.io/crio/private-image",
		"[ -f /etc/containers/registries.conf.bak ] && sudo mv /etc/containers/registries.conf.bak /etc/containers/registries.conf",
		"sudo systemctl restart crio",
		"podman stop registry",
		"echo | sudo tee /etc/containers/mounts.conf",
	)
	return nil
}
