/*
Copyright © 2024 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"fmt"
	"jpconstantineau/sqlqmon/configdatabase"
	"jpconstantineau/sqlqmon/forms"
	"jpconstantineau/sqlqmon/monitoreddatabase"

	"github.com/spf13/cobra"
)

// serverCmd represents the server command
var enableserverCmd = &cobra.Command{
	Use:   "server",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("enable server called")
	},
}

// disableserverCmd represents the server command
var disableserverCmd = &cobra.Command{
	Use:   "server",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("disable server called")
	},
}

// disableserverCmd represents the server command
var addserverCmd = &cobra.Command{
	Use:   "server",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		unsealkeyraw, _ := cmd.Flags().GetString("unsealkey")
		tenant, _ := cmd.Flags().GetString("tenant")
		var keydata configdatabase.SealKey
		keydata = configdatabase.ValidateKey(unsealkeyraw, tenant)
		fmt.Println("Key Validated for: ", keydata.Tenant)

		var data forms.ServerInputForm
		data = forms.GetServerFromUser()
		fmt.Println("Server Name:", data.HostName)
		// save server
		var sdata configdatabase.Server
		sdata = configdatabase.PutServerConfig(data, keydata, unsealkeyraw)
		fmt.Println("Connecting to: ", sdata.Server)
		var name string
		name = monitoreddatabase.GetServerName(sdata)
		fmt.Println("Received ", name)
		configdatabase.UpdateServerConfigbyID(sdata.Id, name)
	},
}

func init() {
	enableCmd.AddCommand(enableserverCmd)
	disableCmd.AddCommand(disableserverCmd)
	addCmd.AddCommand(addserverCmd)
	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// serverCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// serverCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
