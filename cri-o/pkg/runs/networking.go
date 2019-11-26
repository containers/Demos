package runs

import (
	. "github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/urfave/cli"
)

func Networking(ctx *cli.Context) error {
	EnsureInfoLogLevel()

	d := New(
		"Networking",
		"This demo shows how the basic networking works in CRI-O",
	)

	d.Step(S(
		"If not configured, the default location for CRI-O to look for",
		"Container Networking Interface (CNI) configurations is `/etc/cni/net.d`.",
		"For example, a simple bridge interface definition could look like this",
	), S(
		"jq . /etc/cni/net.d/10-crio-bridge.conf",
	))

	d.Step(S(
		"CRI-O picks up the configuration with the highest priority",
		"and applies it to new pods.",
	), S(
		"kubectl run --generator=run-pod/v1 --image=alpine alpine",
		"-- sh -c 'while true; do date; sleep 2; done' &&",
		"kubectl wait pod/alpine --for=condition=ready --timeout=2m",
	))

	d.Step(S(
		"CRI-O tells the CNI plugin to allocate the IP address",
	), S(
		"sudo journalctl -u crio --since '3 minutes ago' | grep -A1 'About to add CNI network'",
	))

	d.Step(S(
		"We now can directly examine the IP addresses of the pod via `crictl`",
	), S(
		"sudo crictl inspectp",
		`$(sudo crictl pods -o json | jq -r '.items[] | select(.metadata.name == "alpine").id') |`,
		"jq '.status | .network, .linux'",
	))

	d.Step(S(
		"The namespace options for the `network` specify if the pod should access the hosts network",
		"For example, the API server runs with host network and got a corresponding IP assigned",
	), S(
		"sudo crictl inspectp",
		`$(sudo crictl pods -o json | jq -r '.items[] |`,
		`select(.metadata.name == "kube-apiserver-'$(hostname)'" and .state == "SANDBOX_READY").id') |`,
		"jq '.status | .network, .linux'",
	))

	d.Step(S(
		"If we delete the workload again, CRI-O takes care of removing the allocated IPs",
	), S(
		"kubectl delete pod alpine --now &&",
		"sudo journalctl -u crio --since '3 minutes ago' | grep -A1 'Got pod network'",
	))

	d.Step(S(
		"CRI-O manages the network namespace lifecycle only if the appropriate configuration",
		"option is set",
	), S(
		"grep -B2 manage_network_ns_lifecycle /etc/crio/crio.conf",
	))

	return d.Run(ctx)
}
