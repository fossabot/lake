// Copyright (c) 2016-2018, Jan Cajthaml <jan.cajthaml@gmail.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"bufio"
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"strings"
	"syscall"

	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	rootCmd = &cobra.Command{
		Use:   "lake",
		Short: "ZMQ Queue",
		Long:  "Single point data lake",
		Run:   CmdRoot,
	}

	runCmd = &cobra.Command{
		Use:   "run",
		Short: "Run the lake",
		Long:  "Run the lake",
		Run:   CmdRun,
	}

	versionCmd = &cobra.Command{
		Use:   "version",
		Short: "Print the version",
		Long:  "",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("%s (build: %s)\n", version, build)
		},
	}

	version string
	build   string
)

// CmdRoot prints usage and help
func CmdRoot(cmd *cobra.Command, args []string) {
	cmd.Help()
}

func setupLogger(params RunParams) {
	level, err := log.ParseLevel(params.LogLevel)
	if err != nil {
		log.Warnf("Invalid log level %v, using level WARN", params.LogLevel)
		return
	}
	log.Infof("Log level set to %v", strings.ToUpper(params.LogLevel))
	log.SetLevel(level)

	if params.Log != "" {
		file, err := os.Create(params.Log)
		if err != nil {
			log.Warnf("Unable to create %s: %v", params.Log, err)
			return
		}
		defer file.Close()

		log.SetOutput(bufio.NewWriter(file))
	}
}

func init() {
	viper.AddConfigPath(filepath.Join("/", ".lake"))

	viper.SetConfigName("config")
	viper.SetConfigType("yml")
	viper.AddConfigPath(".")
	viper.ReadInConfig()

	viper.SetEnvPrefix("LAKE")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	runCmd.Flags().StringP("log-level", "", "", "verbosity of logger")
	runCmd.Flags().StringP("log", "l", "", "file to send logs to; default is STDOUT")

	viper.BindPFlag("log", runCmd.Flags().Lookup("log"))
	viper.BindPFlag("log.level", runCmd.Flags().Lookup("log-level"))

	viper.SetDefault("log.level", "DEBUG")

	rootCmd.AddCommand(runCmd)
	rootCmd.AddCommand(versionCmd)
}

// CmdRun is a main entrypoint for application provided parameters
func CmdRun(cmd *cobra.Command, args []string) {
	params := RunParams{
		viper.GetString("log"),
		viper.GetString("log.level"),
	}

	setupLogger(params)
	runtime.GC()

	log.Infof(">>> Starting <<<")

	go StartRelay()

	exitSignal := make(chan os.Signal)
	signal.Notify(exitSignal, syscall.SIGINT, syscall.SIGTERM)
	<-exitSignal

	log.Infof(">>> Terminating <<<")
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}
