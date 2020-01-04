package runs

import (
	"io/ioutil"

	. "github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/urfave/cli"
)

const r2 = `unqualified-search-registries = ["docker.io"]

[[registry]]
location = "docker.io/library"
mirror = [
 { location = "localhost/mirror-path" },           # doesnt work
 { location = "localhost:5000", insecure = true }, # should work
]
`

func RegistryMirrors(ctx *cli.Context) error {
	if err := ioutil.WriteFile(f, []byte(r2), 0o644); err != nil {
		return err
	}
	Ensure(
		"[ ! -f "+r+".bak ] && sudo mv "+r+" "+r+".bak",
		"sudo cp "+f+" "+r,
		"rm "+f,
		"sudo systemctl reload crio",
	)

	d := New(
		"Registry Mirrors",
		"This demo shows how to configure registries mirrors in CRI-O",
	)

	d.Step(S(
		"Registry mirrors are especially useful in air-gapped scenarios,",
		"where access to the internet is limited.",
		"A registry mirror can be configured like this",
	), S(
		`grep -A5 '^\[\[registry\]\]' `+r,
	))

	d.Step(S(
		"To let the mirror work, we would have to setup one",
		"For this we use podman to setup a local registry",
	), S(
		"podman run --rm --name=registry -p 5000:5000 -d registry",
	))

	d.Step(S(
		"Podman uses the same registry configuration as CRI-O",
		"So we can transfer our target image into the local registry",
	), S(
		"podman pull hello-world &&",
		"podman tag hello-world localhost:5000/hello-world &&",
		"podman push --tls-verify=false localhost:5000/hello-world",
	))

	d.Step(S(
		"If we now pull an image from docker.io, then we first lookup our",
		"configured mirrors.",
	), S(
		"sudo crictl pull hello-world",
	))

	d.Step(S(
		"The logs show us that the image got pulled successfully from the mirror",
	), S(
		"sudo journalctl -u crio --since '1 minute ago' |",
		`grep -Po "(reference rewritten from|Trying to pull|Downloading|GET).*"`,
	))

	return d.Run(ctx)
}
