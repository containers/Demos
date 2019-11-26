package runs

import (
	. "github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/urfave/cli"
)

func Storage(ctx *cli.Context) error {
	d := New(
		"Container Storage",
		"This demo shows how container storage can be configured",
	)

	d.Step(S(
		"The containers storage configuration allows us fine granular",
		"storage adaptions, like changing the directories",
	), S(
		`grep -A9 '^\[storage\]' /etc/containers/storage.conf`,
	))

	d.Step(S(
		"We can also define mounts which should apply for every container",
	), S(
		"echo $(pwd):/mnt | sudo tee /etc/containers/mounts.conf &&",
		"sudo systemctl restart crio",
	))

	d.Step(S(
		"If we now run a container workload,",
		"the mount directory gets attached automatically",
	), S(
		"kubectl run --generator=run-pod/v1 --image=alpine alpine",
		"-- sh -c 'while true; do ls -lah /mnt; sleep 2; done' &&",
		"kubectl wait pod/alpine --for=condition=ready --timeout=2m &&",
		"kubectl logs alpine",
	))

	return d.Run(ctx)
}
