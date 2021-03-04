--use to lookup the row in the graph table from an error message
CREATE OR ALTER PROCEDURE Tools.GraphDB$LookupItem
(
	@ObjectId int,
	@Id int 
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SchemaName sysname = OBJECT_SCHEMA_NAME(@ObjectId),
		    @TableName sysname = OBJECT_NAME(@ObjectId),
	        @SQLStatement nvarchar(MAX)
	SET @SQLStatement = CONCAT('SELECT * FROM ', QUOTENAME(@SchemaName),'.',QUOTENAME(@TableName),
			' WHERE JSON_VALUE(CAST($node_id AS nvarchar(1000)),''$.id'') = ',@Id)

	EXECUTE (@SQLStatement)
END;
GO