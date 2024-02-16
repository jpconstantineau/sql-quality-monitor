/*
Copyright © 2024 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"fmt"
	"jpconstantineau/sqlqmon/configdatabase"
	crypto "jpconstantineau/sqlqmon/crypto"

	"github.com/spf13/cobra"
)

// keyCmd represents the key command
var addkeyCmd = &cobra.Command{
	Use:   "key",
	Short: "Add unseal key used for encrypting database access credentials",
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
	addCmd.AddCommand(addkeyCmd)
	addkeyCmd.Flags().String("unsealkey", "", "unseal key")
	addkeyCmd.Flags().String("tenant", "default", "tenant name for this unseal key")
	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// keyCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// keyCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
