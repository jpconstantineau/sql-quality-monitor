/*
Copyright © 2024 NAME HERE <EMAIL ADDRESS>
*/
package main

import (
	"embed"
	"jpconstantineau/sqlqmon/cmd"
)

//go:embed public
var static_files embed.FS

func main() {
	cmd.Files = static_files
	cmd.Execute()
}
