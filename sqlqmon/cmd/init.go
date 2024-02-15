/*
Copyright © 2024 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"fmt"

	crypto "jpconstantineau/sqlqmon/crypto"
	database "jpconstantineau/sqlqmon/database"

	"github.com/spf13/cobra"
)

// initCmd represents the init command
var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Initialize Configuration and Data Databases",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		database.InitConfigDB()
		database.InitDataDB()
		fmt.Println("Databases Initialized")

		unsealkeyraw, _ := cmd.Flags().GetString("unsealkey")
		tenant, _ := cmd.Flags().GetString("tenant")
		var keydata database.SealKey
		keydata = database.ValidateKey(unsealkeyraw, tenant)

		// hash is used to validate unsealkey
		// keydata.Salt is for AES256 encryption - need to reuse the initial one when decrypting saved credentials

		teststr := "TheQuickBrownFoxJumpsOverTheLazyFoxOrDogLookingThing"
		secret, err := crypto.EncryptSecret(unsealkeyraw, keydata.Salt, teststr)
		if err != nil {
			panic(err)
		}
		fmt.Println("original :  ", teststr)
		fmt.Println("encrypted:  ", secret)
		tmp, err := crypto.DecryptSecret(unsealkeyraw, keydata.Salt, secret)
		if err != nil {
			panic(err)
		}
		fmt.Println("decrypted:  ", tmp)

	},
}

func init() {
	rootCmd.AddCommand(initCmd)
	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// initCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	initCmd.Flags().String("unsealkey", "", "unseal key")
	initCmd.Flags().String("tenant", "default", "tenant name for this unseal key")
}
