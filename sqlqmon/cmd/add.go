/*
Copyright © 2024 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"fmt"

	"jpconstantineau/sqlqmon/database"
	"jpconstantineau/sqlqmon/forms"

	"github.com/spf13/cobra"
)

// addCmd represents the add command
var addCmd = &cobra.Command{
	Use:   "add",
	Short: "Add servers to configuration",
	Long: `Servers must first be added to the configuration before monitoring can start.
The following steps will need to be performed in order to enable monitoring:
- enable server [servername]
- enable database [servername] [databasename]
`,
	Run: func(cmd *cobra.Command, args []string) {
		unsealkeyraw, _ := cmd.Flags().GetString("unsealkey")
		tenant, _ := cmd.Flags().GetString("tenant")
		var keydata database.SealKey
		keydata = database.ValidateKey(unsealkeyraw, tenant)
		fmt.Println("Key Validated for: ", keydata.Tenant)

		var data forms.ServerInputForm
		data = forms.GetServerFromUser()
		fmt.Println("Server Name:", data.HostName)
	},
}

func init() {
	rootCmd.AddCommand(addCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// addCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// addCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	addCmd.Flags().String("unsealkey", "", "unseal key")
	addCmd.Flags().String("tenant", "default", "tenant name for this unseal key")

}
