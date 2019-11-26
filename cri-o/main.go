package main

import (
	"fmt"
	"os"
	"os/signal"
	"time"

	"github.com/containers/Demos/cri-o/pkg/demo"
	"github.com/containers/Demos/cri-o/pkg/runs"
	"github.com/urfave/cli"
)

func main() {
	app := cli.NewApp()
	app.Name = "crio-demos"
	app.Usage = "CRI-O Demonstration Examples"
	app.Authors = []cli.Author{
		{Name: "Sascha Grunert", Email: "sgrunert@suse.com"},
	}
	app.HideVersion = true
	app.UseShortOptionHandling = true
	app.Before = demo.Setup
	app.After = demo.Cleanup
	app.Flags = []cli.Flag{
		cli.BoolFlag{
			Name:  "1, interaction",
			Usage: "this demo shows basic interactions with CRI-O, the kubelet and between both of them",
		},
		cli.BoolFlag{
			Name:  "2, logging",
			Usage: "this demo shows how to configure CRI-O logging and reload the configuration during runtime",
		},
		cli.BoolFlag{
			Name:  "3, lifecycle",
			Usage: "this demo shows how CRI-O ensures the containers life-cycle in conjunction with the kubelet",
		},
		cli.BoolFlag{
			Name:  "4, port-forward",
			Usage: "this demo shows how port forwaring works in CRI-O",
		},
		cli.BoolFlag{
			Name:  "5, recovering",
			Usage: "this demo shows what happens if a workload unexpectedly stops",
		},
		cli.BoolFlag{
			Name:  "6, networking",
			Usage: "this demo shows how the basic networking works in CRI-O",
		},
		cli.BoolFlag{
			Name:  "7, pull-auth",
			Usage: "this demo shows how registry authentication works in CRI-O",
		},
		cli.BoolFlag{
			Name:  "8, registries",
			Usage: "this demo shows how to configure registries with CRI-O",
		},
		cli.BoolFlag{
			Name:  "9, registry-mirrors",
			Usage: "this demo shows how to configure registries mirrors in CRI-O",
		},
		cli.BoolFlag{
			Name:  "10, storage",
			Usage: "this demo shows how container storage can be configured",
		},
		cli.BoolFlag{
			Name:  "all, l",
			Usage: "run all demos",
		},
		cli.BoolFlag{
			Name: "auto, a",
			Usage: "run the demo in automatic mode, " +
				"where every step gets executed automatically",
		},
		cli.DurationFlag{
			Name:  "auto-timeout, t",
			Usage: "the timeout to be waited when `auto` is enabled",
			Value: 3 * time.Second,
		},
		cli.BoolFlag{
			Name:  "continuously, c",
			Usage: "run the demos continuously without any end",
		},
		cli.BoolFlag{
			Name:  "immediate, i",
			Usage: "immediately output without the typewriter animation",
		},
		cli.IntFlag{
			Name:  "skip-steps, s",
			Usage: "skip the amount of initial steps within the demo",
		},
	}
	app.Action = func(ctx *cli.Context) error {
		demos := []cli.ActionFunc{}
		all := ctx.GlobalBool("all")

		if all || ctx.GlobalBool("interaction") {
			demos = append(demos, runs.Interaction)
		}
		if all || ctx.GlobalBool("logging") {
			demos = append(demos, runs.Logging)
		}
		if all || ctx.GlobalBool("lifecycle") {
			demos = append(demos, runs.LifeCycle)
		}
		if all || ctx.GlobalBool("port-forward") {
			demos = append(demos, runs.PortForward)
		}
		if all || ctx.GlobalBool("recovering") {
			demos = append(demos, runs.Recovering)
		}
		if all || ctx.GlobalBool("networking") {
			demos = append(demos, runs.Networking)
		}
		if all || ctx.GlobalBool("pull-auth") {
			demos = append(demos, runs.PullAuth)
		}
		if all || ctx.GlobalBool("registries") {
			demos = append(demos, runs.Registries)
		}
		if all || ctx.GlobalBool("registry-mirrors") {
			demos = append(demos, runs.RegistryMirrors)
		}
		if all || ctx.GlobalBool("storage") {
			demos = append(demos, runs.Storage)
		}

		runDemos := func() error {
			for _, runDemo := range demos {
				if err := runDemo(ctx); err != nil {
					return err
				}
				if err := demo.Setup(ctx); err != nil {
					return err
				}
			}
			return nil
		}
		if ctx.GlobalBool("continuously") {
			for {
				if err := runDemos(); err != nil {
					return err
				}
			}
		}
		return runDemos()
	}

	// Catch interrupts and cleanup
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)
	go func() {
		for range c {
			_ = demo.Cleanup(nil)
			os.Exit(0)
		}
	}()

	if err := app.Run(os.Args); err != nil {
		fmt.Printf("run failed: %v", err)
		os.Exit(1)
	}
}
