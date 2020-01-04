package runs

import (
	. "github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/urfave/cli"
)

func Interaction(ctx *cli.Context) error {
	d := New(
		"Basic interactions with CRI-O",
		"This demo shows basic interactions with CRI-O, the kubelet",
		"and between both of them",
	)

	d.Step(S(
		"The recommended way of running CRI-O is within a systemd unit.",
		"Let’s verify that CRI-O is running as expected",
	), S(
		"sudo systemctl --no-pager status crio",
	))

	d.Step(S(
		"If CRI-O is up and running, then a kubelet instance can",
		"be configured to run CRI-O",
	), S(
		"sudo systemctl --no-pager status kubelet",
	))

	d.Step(S(
		"We can use the tool `crictl` to interact with the Container Runtime ",
		"Interface (CRI). To let this work out of the box with CRI-O, we",
		"just have to adapt the configuration file `/etc/crictl.yaml`.",
	), S(
		"cat /etc/crictl.yaml",
	))

	d.Step(S(
		"We should be now able to interact with CRI-O via `crictl`",
	), S(
		"sudo crictl version",
	))

	d.Step(S(
		"We can list the pods and their status",
	), S(
		"sudo crictl pods",
	))

	d.Step(S(
		"Or the containers",
	), S(
		"sudo crictl ps -a",
	))

	d.Step(S(
		"All crictl calls result in direct gRPC request to CRI-O",
		"For example, `crictl ps` results in a `ListContainersRequest`.",
	), S(
		"sudo journalctl -u crio --since '1 seconds ago' |",
		"grep -Po '.*ListContainers(Request|Response){.*?}'",
	))

	d.Step(S(
		"It looks like that the kubelet generally syncs periodically",
		"with CRI-O.",
	), S(
		"sudo journalctl -u crio --no-pager --since '2 seconds ago' |",
		"grep -Po 'time.*(Request|Response)'",
	))

	return d.Run(ctx)
}
