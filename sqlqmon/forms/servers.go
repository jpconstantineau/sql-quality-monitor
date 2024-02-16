package forms

import (
	"errors"
	"log"
	"strconv"

	"github.com/charmbracelet/huh"
)

type ServerInputForm struct {
	HostName  string
	Port      string
	UserName  string
	Password  string
	Monitored bool
}

func GetServerFromUser() ServerInputForm {
	var data ServerInputForm
	form := huh.NewForm(
		huh.NewGroup(
			huh.NewInput().Title("SQL Server Host\\Instance").Value(&data.HostName),
			huh.NewInput().Title("SQL Server Port").Value(&data.Port).Validate(func(str string) error {
				_, err := strconv.Atoi(str)
				if err != nil {
					return errors.New("Need port number (integer)")
				}
				return nil
			})),
		huh.NewGroup(
			huh.NewInput().Title("SQL Login Name").Value(&data.UserName),
			huh.NewInput().Title("SQL Login Password").Description("will be encrypted").Value(&data.Password)),
		huh.NewGroup(
			huh.NewConfirm().Title("Turn Monitoring On").Affirmative("Yes!").Negative("No.").Value(&data.Monitored),
		),
	)

	err := form.Run()
	if err != nil {
		log.Fatal(err)
	}
	return data
}
