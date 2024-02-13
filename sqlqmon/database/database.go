package database

import (
	"database/sql"

	_ "modernc.org/sqlite"
)

func connectSqliteDB(dbPath string) (*sql.DB, error) {
	// Note: the busy_timeout pragma must be first because
	// the connection needs to be set to block on busy before WAL mode
	// is set in case it hasn't been already set by another connection.
	pragmas := "?_pragma=busy_timeout(10000)&_pragma=journal_mode(WAL)&_pragma=journal_size_limit(200000000)&_pragma=synchronous(NORMAL)&_pragma=foreign_keys(ON)"

	db, err := sql.Open("sqlite", dbPath+pragmas)
	if err != nil {
		return nil, err
	}
	return db, nil
}

func InitConfigDB() {
	db, err := connectSqliteDB("./ConfigDB.db")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS sealedkeys (
		id INTEGER PRIMARY KEY,
		salt TEXT NOT NULL,
		hash TEXT NOT NULL,
		tenant TEXT NOT NULL,
		enabled INTEGER
		); `)

	if err != nil {
		panic(err)
	}

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS servers (
		id INTEGER PRIMARY KEY,
		tenantid INTEGER NOT NULL,
		Server TEXT NOT NULL,
		Instance TEXT NOT NULL,
		Port INTEGER NOT NULL,
		User TEXT NOT NULL,
		Password TEXT NOT NULL,
		ServerName TEXT NOT NULL,
		Monitored INTEGER NOT NULL,
		FOREIGN KEY (tenantid)
			REFERENCES sealedkeys (id) 
		); `)

	if err != nil {
		panic(err)
	}

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS databases (
		id INTEGER PRIMARY KEY,
		ServerId INTEGER NOT NULL,
		DatabaseName TEXT NOT NULL,
		Monitored INTEGER NOT NULL,
		Daily INTEGER NOT NULL,
		RealTime INTEGER NOT NULL,
		FOREIGN KEY (ServerId)
		REFERENCES servers (id) 
		); `)

	if err != nil {
		panic(err)
	}

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS tables (
		id INTEGER PRIMARY KEY,
		DatabaseId INTEGER NOT NULL,
		SchemaName TEXT NOT NULL,
		TableName TEXT NOT NULL,
		RealTime INTEGER NOT NULL,
		FOREIGN KEY (DatabaseId)
		REFERENCES databases (id) 
		); `)

	if err != nil {
		panic(err)
	}

}

func InitDataDB() {
	db, err := connectSqliteDB("./DataDB.db")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS serverprincipals (
		id INTEGER PRIMARY KEY,
		ServerName TEXT NOT NULL,
		UserName TEXT NOT NULL,
		type_desc TEXT NOT NULL,
		is_disabled INTEGER NULL,
		create_date TEXT NOT NULL,
		modify_date TEXT NOT NULL,
		default_database_name TEXT NULL,
		default_language_name TEXT NULL
		); `)

	if err != nil {
		panic(err)
	}

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS databases (
		id INTEGER PRIMARY KEY,
		ServerName TEXT NOT NULL,
		DatabaseName TEXT NOT NULL,
		create_date TEXT,
		collation_name TEXT NULL,
		user_access_desc TEXT NULL,
		state_desc TEXT NULL,
		recovery_model_desc TEXT NULL
		); `)

	if err != nil {
		panic(err)
	}

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS tables (
			id INTEGER PRIMARY KEY,
			ServerName TEXT NOT NULL,
			DatabaseName TEXT NOT NULL,
			SchemaName TEXT NOT NULL,
			TableName TEXT NOT NULL,
			rows INTEGER NULL,
			TotalSpaceKB INTEGER NULL,
			TotalSpaceMB REAL NULL,
			UsedSpaceKB INTEGER NULL,
			UsedSpaceMB REAL NULL,
			UnusedSpaceKB INTEGER NULL,
			UnusedSpaceMB REAL NULL,
			last_access TEXT NULL,
			last_user_update TEXT NULL
			); `)

	if err != nil {
		panic(err)
	}

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS columns (
				id INTEGER PRIMARY KEY,
				ServerName TEXT NOT NULL,
				DatabaseName TEXT NOT NULL,
				SchemaName TEXT NOT NULL,
				TableName TEXT NOT NULL,
				COLUMN_NAME TEXT NULL,
				ORDINAL_POSITION INTEGER NULL,
				COLUMN_DEFAULT TEXT NULL,
				IS_NULLABLE TEXT NULL,
				DATA_TYPE TEXT NULL,
				CHARACTER_MAXIMUM_LENGTH TEXT NULL,
				CHARACTER_OCTET_LENGTH TEXT NULL,
				NUMERIC_PRECISION INTEGER NULL,
				NUMERIC_PRECISION_RADIX INTEGER NULL,
				NUMERIC_SCALE INTEGER NULL,
				DATETIME_PRECISION INTEGER NULL,
				CHARACTER_SET_CATALOG TEXT NULL,
				CHARACTER_SET_SCHEMA TEXT NULL,
				CHARACTER_SET_NAME TEXT NULL,
				COLLATION_CATALOG TEXT NULL,
				COLLATION_SCHEMA TEXT NULL,
				COLLATION_NAME TEXT NULL,
				DOMAIN_CATALOG TEXT NULL,
				DOMAIN_SCHEMA TEXT NULL,
				DOMAIN_NAME TEXT NULL
				); `)

	if err != nil {
		panic(err)
	}

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS rows (
		id INTEGER PRIMARY KEY,
		ServerName TEXT NOT NULL,
		DatabaseName TEXT NOT NULL,
		SchemaName TEXT NOT NULL,
		TableName TEXT NOT NULL,
		rows INTEGER NULL
		); `)

	if err != nil {
		panic(err)
	}

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY,
		ServerName TEXT NOT NULL,
		DatabaseName TEXT NOT NULL,
		Login TEXT NOT NULL,
		hostname TEXT NOT NULL,
		ProgramName TEXT NULL,
		LastBatch TEXT NOT NULL
		); `)

	if err != nil {
		panic(err)
	}

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS jobs (
		id INTEGER PRIMARY KEY,
		ServerName TEXT NOT NULL,
		JobName TEXT NOT NULL,
		TimeRun TEXT NULL,
		JobStatus TEXT NOT NULL,
		enabled INTEGER NOT NULL,
		JobOutcome TEXT NOT NULL,
		run_status INTEGER NOT NULL
		); `)

	if err != nil {
		panic(err)
	}

}
