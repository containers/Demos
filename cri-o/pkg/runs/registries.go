package runs

import (
	"io/ioutil"

	. "github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/urfave/cli"
)

const r1 = `# An array of host[:port] registries to try when
# pulling an unqualified image, in order.
unqualified-search-registries = ["docker.io", "quay.io"]

[[registry]]
prefix = "localhost"
location = "docker.io/library"
blocked = false
insecure = false
`

const (
	f = "registries.conf"
	r = "/etc/containers/" + f
)

func Registries(ctx *cli.Context) error {
	if err := ioutil.WriteFile(f, []byte(r1), 0o644); err != nil {
		return err
	}
	Ensure(
		"[ ! -f "+r+".bak ] && sudo mv "+r+" "+r+".bak",
		"sudo cp "+f+" "+r,
		"rm "+f,
		"sudo systemctl reload crio",
	)

	d := New(
		"Registry Configurations",
		"This demo shows how to configure registries with CRI-O",
	)

	d.Step(S(
		"CRI-O supports multiple registry configuration syntaxes.",
		"From now on we focus on the latest version, which comes with the",
		"highest set of features. The default configuration can be found",
		"at "+r,
	), S(
		"grep -B2 unqualified-search-registries "+r,
	))

	d.Step(S(
		"The `unqualified-search-registries` allows us to pull images without",
		"prepending a registry prefix",
	), S(
		"sudo crictl -D pull hello-world",
	))

	d.Step(S(
		"A single registry can be specified within a [[registry]] entry",
	), S(
		`grep -A4 '^\[\[registry\]\]' `+r,
	))

	d.Step(S(
		"We have been rewritten the docker library to localhost.",
		"Now it is possible to pull via localhost",
	), S(
		"sudo crictl -D pull localhost/alpine",
	))

	d.Step(S(
		"The logs indicate that the rewrite was successful",
	), S(
		"sudo journalctl -u crio --since '1 minute ago' |",
		`grep -o "reference rewritten from 'localhost/alpine:latest'.*"`,
	))

	return d.Run(ctx)
}
