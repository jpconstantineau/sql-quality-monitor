package configdatabase

import (
	"database/sql"
	"fmt"
	crypto "jpconstantineau/sqlqmon/crypto"
	"jpconstantineau/sqlqmon/forms"
	"log"
	"os"
	"time"

	_ "modernc.org/sqlite"
)

// ------------------- GENERIC DB FUNCTIONS -------------------
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

type SealKey struct {
	Id      int64
	Salt    int64
	Hash    string
	Tenant  string
	Enabled bool
}

type Server struct {
	Id         int64
	Tenantid   int64
	Server     string
	Instance   string
	Port       string
	User       string
	Password   string
	ServerName string
	Monitored  bool
}

// ------------------- CONFIG DB FUNCTIONS -------------------
func InitConfigDB() {
	db, err := connectSqliteDB("./ConfigDB.db")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS sealkeys (
		id INTEGER PRIMARY KEY,
		salt INTEGER NOT NULL,
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
		Port INTEGER NOT NULL,
		User TEXT NOT NULL,
		Password TEXT NOT NULL,
		ServerName TEXT NOT NULL,
		Monitored INTEGER NOT NULL,
		FOREIGN KEY (tenantid)
			REFERENCES sealkeys (id) 
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

func GetSealKey(tenant string) (key SealKey) {
	var initkey SealKey

	initkey.Id = 0
	initkey.Salt = 0
	initkey.Hash = ""
	initkey.Tenant = ""
	initkey.Enabled = false

	db, err := connectSqliteDB("./ConfigDB.db")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	row := db.QueryRow("SELECT id, salt, hash, tenant, enabled FROM sealkeys WHERE enabled = 1 AND tenant=?", tenant)

	if err = row.Scan(&initkey.Id, &initkey.Salt, &initkey.Hash, &initkey.Tenant, &initkey.Enabled); err == sql.ErrNoRows {
		log.Printf("tenant not found")
		return initkey
	}

	return initkey
}

func PutSealKey(tenant string, hashBase64 string, saltyint int64) (key SealKey) {
	db, err := connectSqliteDB("./ConfigDB.db")
	if err != nil {
		panic(err)
	}
	defer db.Close()
	var enabled bool
	enabled = true
	res, err := db.Exec("INSERT INTO sealkeys VALUES(NULL,?,?,?,?);", saltyint, hashBase64, tenant, enabled)
	if err != nil {
		panic(err)
	}

	var id int64
	id, err = res.LastInsertId()
	if err != nil {
		panic(err)
	}
	fmt.Println("Inserted ID: ", id)
	return GetSealKey(tenant)
}

func ValidateKey(unsealkey string, tenant string) (key SealKey) {
	hashBase64, _ := crypto.HashPassword(unsealkey)

	// get stored hashBase64 and saltyint from DB for this tenant

	keydata := GetSealKey(tenant)

	if keydata.Enabled { // if tenant is present check if it's the same
		// Compare with the currently entered unsealkey
		if !crypto.ComparePassword(keydata.Hash, unsealkey) {
			fmt.Println("Keys do not match")
			os.Exit(1)
		}
	} else // if not present - add hashBase64 and to db
	{
		saltyint := time.Now().UnixNano()
		keydata = PutSealKey(tenant, hashBase64, saltyint)
	}

	return keydata
}

func PutServerConfig(data forms.ServerInputForm, keydata SealKey, unsealkey string) Server {
	db, err := connectSqliteDB("./ConfigDB.db")
	if err != nil {
		panic(err)
	}
	defer db.Close()
	User, err := crypto.EncryptSecret(unsealkey, keydata.Salt, data.UserName)
	if err != nil {
		panic(err)
	}
	Password, err := crypto.EncryptSecret(unsealkey, keydata.Salt, data.Password)
	if err != nil {
		panic(err)
	}

	res, err := db.Exec("INSERT INTO servers VALUES(NULL,?,?,?,?,?,?,?);", keydata.Id, data.HostName, data.Port, User, Password, "", data.Monitored)
	if err != nil {
		panic(err)
	}

	var id int64
	id, err = res.LastInsertId()
	if err != nil {
		panic(err)
	}
	fmt.Println("Inserted ID: ", id)
	return GetServerConfigbyID(id, keydata, unsealkey)
}

func UpdateServerConfigbyID(id int64, name string) {
	db, err := connectSqliteDB("./ConfigDB.db")
	if err != nil {
		panic(err)
	}
	defer db.Close()
	res, err := db.Exec("UPDATE servers SET ServerName = ? WHERE id = ?;", id, name)
	if err != nil {
		panic(err)
	}
	var rowid int64
	rowid, err = res.LastInsertId()
	if err != nil {
		panic(err)
	}
	fmt.Println("Inserted ID: ", rowid)

}

func GetServerConfigbyID(id int64, keydata SealKey, unsealkey string) Server {
	var data Server
	db, err := connectSqliteDB("./ConfigDB.db")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	row := db.QueryRow("SELECT id, tenantid, Server,  Port, User, Password, ServerName, Monitored FROM Servers WHERE id=?", id)

	if err = row.Scan(&data.Id, &data.Tenantid, &data.Server, &data.Port, &data.User, &data.Password, &data.ServerName, &data.Monitored); err == sql.ErrNoRows {
		log.Printf("Server ID not found")
		return data
	}

	User, err := crypto.DecryptSecret(unsealkey, keydata.Salt, data.User)
	if err != nil {
		panic(err)
	}
	Password, err := crypto.DecryptSecret(unsealkey, keydata.Salt, data.Password)
	if err != nil {
		panic(err)
	}
	data.User = User
	data.Password = Password
	return data
}

// ------------------- DATA DB FUNCTIONS -------------------
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
