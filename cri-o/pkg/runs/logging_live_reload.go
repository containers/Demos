package runs

import (
	. "github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/urfave/cli"
)

func Logging(ctx *cli.Context) error {
	EnsureInfoLogLevel()

	d := New(
		"Logging and configuration reload",
		"This demo shows how to configure CRI-O logging and",
		"reload the configuration during runtime",
	)

	d.Step(S(
		"The basic configuration file of CRI-O is available in",
		"/etc/crio/crio.conf",
	), S(
		"head -11 /etc/crio/crio.conf",
	))

	d.Step(S(
		"For example, the log level can be changed there too",
	), S(
		"grep -B3 log_level /etc/crio/crio.conf",
	))

	d.Step(S(
		"So we can set the `log_level` to a higher verbosity",
	), S(
		`sudo sed -i -E 's/(log_level = )(.*)/\1"debug"/' /etc/crio/crio.conf &&`,
		"grep -B3 log_level /etc/crio/crio.conf",
	))

	d.Step(S(
		"To reload CRI-O, we have to send a SIGHUP (hangup) to the process.",
		"This can be done via `systemctl reload` for your convenience.",
	), S(
		"sudo systemctl reload crio",
	))

	d.Step(S(
		"The logs indicate that the configuration has been reloaded correctly",
	), S(
		"sudo journalctl -u crio --since '30 seconds ago' |",
		"grep -A3 reloading",
	))

	d.Step(S(
		"CRI-O now logs every request and response in debug mode",
	), S(
		`sudo journalctl -u crio --no-pager -n 5 | cut -c-130`,
	))

	return d.Run(ctx)
}
