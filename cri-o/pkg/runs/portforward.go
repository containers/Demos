package runs

import (
	. "github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/urfave/cli"
)

func PortForward(ctx *cli.Context) error {
	d := New(
		"Port Forwarding",
		"This demo shows how port forwaring works in CRI-O",
	)

	d.Step(S(
		"First, let’s create a workload which we want to access",
		"In our case an example nginx server",
	), S(
		"kubectl run --generator=run-pod/v1 --image=nginx:1.17-alpine nginx &&",
		"kubectl wait pod/nginx --for=condition=ready --timeout=2m",
	))

	d.Step(S(
		"Then, a port-forward can be done using kubectl",
	), S(
		"kubectl port-forward pod/nginx 8888:80 &",
	))

	d.Step(S(
		"Now we’re able to access the pod via localhost",
	), S(
		"curl 127.0.0.1:8888",
	))

	d.Step(S(
		"During port forward, CRI-O returns a streaming endpoint to the kubelet",
	), S(
		"sudo journalctl -u crio --since '3 minutes ago' | grep -E '(PortForward(Request|Response)|socat).*'",
	))

	d.Step(S(
		"It looks like that running socat inside the PID namespace is",
		"the way to achieve the port forward.",
		"This means we could use `socat` directly to access the web server",
		"after entering the PID namespace",
	), S(
		`echo "GET /" |`,
		`sudo $(sudo journalctl -u crio --since '2 minute ago' |`,
		`sed -n -E 's;.*executing port forwarding command: (.*80).*;\1;p')`,
	))

	return d.Run(ctx)
}
