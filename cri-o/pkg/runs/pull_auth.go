package runs

import (
	"os"

	. "github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/urfave/cli"
)

func PullAuth(ctx *cli.Context) error {
	Ensure(
		"sudo crictl rmi quay.io/crio/private-image",
		`sudo sed -i -E 's/(global_auth_file = )(.*)/\1""/' /etc/crio/crio.conf`,
		"sudo systemctl restart crio",
	)

	d := New(
		"Image Pull Authentication",
		"This demo shows how registry authentication works in CRI-O",
		"(Please be aware that this demo does not work if the credentials",
		"are not valid)",
	)

	d.Step(S(
		"With the default configuration, CRI-O is not able to pull private images",
	), S(
		"sudo crictl -D pull quay.io/crio/private-image || true",
	))

	d.Step(S(
		"But CRI-O is able to reuse the Docker authentication configuration as well",
	), S(
		`sudo sed -i -E 's;(global_auth_file = )(.*);\1"`+os.Getenv("HOME")+
			`/.docker/config.json";' /etc/crio/crio.conf &&`,
		"grep -B2 global_auth_file /etc/crio/crio.conf",
	))

	d.Step(S(
		"The `global_auth_file` configuration does not support live configuration yet.",
		"Which means that we have to restart CRI-O.",
		"This is totally safe, since CRI-O relies only on the state on disk.",
	), S(
		"sudo systemctl restart crio",
	))

	d.Step(S(
		"If the credentials inside this file are valid,",
		"then CRI-O can pull private images too",
	), S(
		"sudo crictl pull quay.io/crio/private-image",
	))

	d.Step(S(
		"We can see that the `containers/image` library takes care of the",
		"authentication. Kubernetes is not involved in the authentication",
		"at all in this demo",
	), S(
		"sudo journalctl -u crio --since '1 minute ago' |",
		"grep -oP '(PullImageRequest|GET).*'",
	))

	return d.Run(ctx)
}
