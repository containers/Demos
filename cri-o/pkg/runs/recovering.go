package runs

import (
	. "github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/urfave/cli"
)

func Recovering(ctx *cli.Context) error {
	d := New(
		"Recovering Workloads",
		"This demo shows what happens if a workload unexpectedly stops",
	)

	d.Step(S(
		"Let’s start with a fresh nginx deployment",
	), S(
		"kubectl create deployment --image=nginx:1.17-alpine nginx &&",
		"kubectl wait deploy/nginx --for=condition=available --timeout=2m",
	))

	d.Step(S(
		"Now we kill the container’s nginx process",
	), S(
		"sudo pkill -KILL nginx",
	))

	d.Step(S(
		"Then, the container monitor `conmon` will notice that",
		"something bad happened and CRI-O removes the workload.",
	), S(
		"sudo journalctl -u crio --since '30 seconds ago' | grep exited",
	))

	d.Step(S(
		"The kubelet’s synchronization loop will notice that",
		"the workload does not exist any more and will re-schedule it",
	), S(
		"sudo journalctl -u kubelet --since '2 minute ago' | grep -A1 ContainerDied",
	))

	d.Step(S(
		"The kubelet’s synchronization loop will watch over all workloads.",
		"This means if we manually create a pod like this",
	), S(
		`echo '{ "metadata": { "name": "test-sandbox", "namespace": "default" } }'`,
		"> /tmp/sandbox.json &&",
		"sudo crictl runp /tmp/sandbox.json",
	))

	d.Step(S(
		"Then the kubelet will remove it again",
	), S(
		"sudo journalctl -u kubelet --since '1 minute ago' | grep unwanted",
	))

	return d.Run(ctx)
}
