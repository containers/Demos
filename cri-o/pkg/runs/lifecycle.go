package runs

import (
	. "github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/urfave/cli"
)

func LifeCycle(ctx *cli.Context) error {
	d := New(
		"Life Cycle of a Kubernetes workload",
		"This demo shows how CRI-O ensures the containers life-cycle",
		"in conjunction with the kubelet",
	)

	d.Step(S(
		"Multiple steps are needed by CRI-O to run a container workload",
		"First, let’s create a new pod printing out the current date every 2 seconds",
	), S(
		"kubectl run --generator=run-pod/v1 --image=alpine alpine",
		"-- sh -c 'while true; do date; sleep 2; done' &&",
		"kubectl wait pod/alpine --for=condition=ready --timeout=2m",
	))

	d.Step(S(
		"The first thing CRI-O has to accomplish is setting up the pod sandbox",
	), S(
		"sudo journalctl -u crio --since '5 minutes ago' |",
		"grep -P 'RunPodSandbox(Request|Response)'",
	))

	d.Step(S(
		"The `RunPodSandboxRequest` already contains a lot of information",
		"for CRI-O to prepare an isolated environment for Kubernetes workloads.",
		"The resulting sandbox can now be examined via `crictl`",
	), S(
		"sudo crictl inspectp",
		`$(sudo crictl pods -o json | jq -r '.items[] | select(.metadata.name == "alpine").id') |`,
		"jq .",
	))

	d.Step(S(
		"The data from `crictl inspectp` is retrieved via a `PodSandboxStatusRequest`,",
		"which is continuously called by the kubelet during its synchronization loop.",
		"The sandbox seems ready, now the kubelet has to ensure that the image exists",
		"on the target node. This is done by a `PullImageRequest`",
	), S(
		"sudo journalctl -u crio --since '5 minutes ago' | grep -P 'PullImage(Request|Response)'",
	))

	d.Step(S(
		"It looks like that the image should be available on the node",
	), S(
		"sudo crictl images -o yaml alpine",
	))

	d.Step(S(
		"CRI-O can now create the container workload",
	), S(
		"sudo journalctl -u crio --since '5 minutes ago' | grep -P 'CreateContainer(Request|Response)'",
	))

	d.Step(S(
		"A container is not started by default. The kubelet will call a `StartContainerRequest`",
		"to CRI-O to start the workload",
	), S(
		"sudo journalctl -u crio --since '5 minutes ago' | grep -P 'StartContainer(Request|Response)'",
	))

	d.Step(S(
		"The kubelet continuously verifies that the workload is still running",
		"We can do this too, via `crictl ps` or `crictl inspect`",
	), S(
		"sudo crictl inspect",
		`$(sudo crictl ps -o json | jq -r '.containers[] | select(.metadata.name == "alpine").id') |`,
		"jq .",
	))

	d.Step(S(
		"Now since the container is running, we should be able to retrieve its logs",
	), S(
		"kubectl logs alpine",
	))

	d.Step(S(
		"The container logs are retrieved directly from the local log path",
	), S(
		"sudo tail",
		"$(sudo crictl inspect",
		`$(sudo crictl ps -o json | jq -r '.containers[] | select(.metadata.name == "alpine").id') | jq -r .status.logPath)`,
	))

	d.Step(S(
		"We can also exec the container and run another command in parallel",
	), S(
		`kubectl exec alpine echo Hello World`,
	))

	d.Step(S(
		"A `kubectl exec` results in an `ExecRequest` to CRI-O, initiated by the kubelet",
	), S(
		"sudo journalctl -u crio --since '1 minutes ago' | grep Exec",
	))

	d.Step(S(
		"The lifecycle of a kubernetes workload can also be examined by the kubelets events",
	), S(
		"kubectl get events --field-selector=involvedObject.kind=Pod,involvedObject.name=alpine",
	))

	d.Step(S(
		"If we delete the workload again, CRI-O takes care of removing the system resources",
	), S(
		"kubectl delete pod alpine --now &&",
		"sudo journalctl -u crio --since '2 minute ago' | grep -oE '(Stop|Remove).*'",
	))

	return d.Run(ctx)
}
