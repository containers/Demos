package runs

import (
	. "github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/urfave/cli"
)

func Example(ctx *cli.Context) error {
	d := New(
		"Title",
		"Some additional",
		"multiline description",
	)

	d.Step(S(
		"This is a possible",
		"description of the command",
		"to be executed",
	), S(
		"echo hello world",
	))

	// Commands to not need to have a description
	d.Step(nil, S(
		"echo without description",
	))

	// It is also not needed to provide a command
	d.Step(S(
		"Just a description without a command",
	), nil)

	return d.Run(ctx)
}
