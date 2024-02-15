package forms

type TableInputForm struct {
	ServerId   int
	DatabaseId int
	SchemaName string
	TableName  string
	RealTime   bool
}
