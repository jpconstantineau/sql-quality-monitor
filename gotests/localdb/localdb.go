package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "modernc.org/sqlite"
)

func main() {
	fmt.Println("Hello")
	db, err := sql.Open("sqlite", "./localDB.db")
	if err != nil {
		panic(err)
	}
	_, err = db.Exec("CREATE TABLE `customers` (`till_id` INTEGER PRIMARY KEY AUTOINCREMENT, `client_id` VARCHAR(64) NULL, `first_name` VARCHAR(255) NOT NULL, `last_name` VARCHAR(255) NOT NULL, `guid` VARCHAR(255) NULL, `dob` DATETIME NULL, `type` VARCHAR(1))")
	if err != nil {
		log.Fatal(err)
	}
}
