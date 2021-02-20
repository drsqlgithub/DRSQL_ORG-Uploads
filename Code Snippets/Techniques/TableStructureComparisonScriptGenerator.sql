DECLARE @schema_name_LIKE sysname = 'adam';
DECLARE @table_name_LIKE sysname = '%';
DECLARE @column_name_LIKE sysname = '%';
DECLARE @SQLQUERY nvarchar(MAX);

SET @SQLQUERY = 'WITH SourceStructure AS (SELECT *
				 FROM   (VALUES ';

SET NOCOUNT ON;

SELECT @SQLQUERY
    = @SQLQUERY
      + CONCAT(
            '(',
            QUOTENAME(COLUMNS.TABLE_SCHEMA, ''''),
            ',',                                                          --CHAR(13), CHAR(10),
            QUOTENAME(COLUMNS.TABLE_NAME, ''''),
            ',',                                                          --CHAR(13), CHAR(10) ,
            QUOTENAME(COLUMNS.COLUMN_NAME, ''''),
            ',',                                                          --CHAR(13), CHAR(10),
            QUOTENAME(COLUMNS.DATA_TYPE, ''''),
            ',',                                                          --CHAR(13), CHAR(10) ,, CHAR(13), CHAR(10) ,
            QUOTENAME(COLUMNS.IS_NULLABLE, ''''),
            ',',                                                          --CHAR(13), CHAR(10) , 
            QUOTENAME(COALESCE(COLUMNS.CHARACTER_MAXIMUM_LENGTH, -9999), ''''),
            ',',
            QUOTENAME(COALESCE(COLUMNS.NUMERIC_PRECISION, -9999), ''''),
            ',',                                                          --CHAR(13), CHAR(10) ,
            QUOTENAME(COALESCE(COLUMNS.NUMERIC_PRECISION_RADIX, -9999), ''''),
            ',',                                                          --CHAR(13), CHAR(10) ,
            QUOTENAME(COALESCE(COLUMNS.NUMERIC_SCALE, -9999), ''''),
            ',',                                                          --CHAR(13), CHAR(10) ,
            QUOTENAME(COALESCE(COLUMNS.DATETIME_PRECISION, -9999), ''''), --CHAR(13), CHAR(10),
            '),',
            CHAR(13),
            CHAR(10))
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  COLUMNS.TABLE_SCHEMA LIKE @schema_name_LIKE
    AND COLUMNS.TABLE_NAME LIKE @table_name_LIKE
    AND COLUMNS.COLUMN_NAME LIKE @column_name_LIKE;

SELECT @SQLQUERY = SUBSTRING(@SQLQUERY, 1, LEN(@SQLQUERY) - 3); --3 includes the CRLF

SELECT @SQLQUERY
    = @SQLQUERY
      + ') AS Existing (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE, DATETIME_PRECISION))
, FormatLayer as (
SELECT SourceStructure.*,
		COLUMNS.TABLE_SCHEMA AS Target_TABLE_SCHEMA,
		COLUMNS.TABLE_NAME AS Target_TABLE_NAME,
		COLUMNS.COLUMN_NAME AS Target_COLUMN_NAME,
	   COLUMNS.DATA_TYPE AS Target_DATA_TYPE,
	   COLUMNS.IS_NULLABLE as Target_IS_NULLABLE,
	   COALESCE(COLUMNS.CHARACTER_MAXIMUM_LENGTH,-9999) AS Target_CHARACTER_MAXIMUM_LENGTH,
	   COALESCE(COLUMNS.NUMERIC_PRECISION,-9999) AS Target_NUMERIC_PRECISION,
	   COALESCE(COLUMNS.NUMERIC_PRECISION_RADIX,-9999) AS Target_NUMERIC_PRECISION_RADIX,
	   COALESCE(COLUMNS.NUMERIC_SCALE,-9999) AS Target_NUMERIC_SCALE,
	   COALESCE(COLUMNS.DATETIME_PRECISION,-9999) AS Target_DATETIME_PRECISION
FROM   SourceStructure
		FULL OUTER JOIN 
			INFORMATION_SCHEMA.COLUMNS	
				ON COLUMNS.TABLE_SCHEMA = SourceStructure.TABLE_SCHEMA
				   AND COLUMNS.TABLE_NAME = SourceStructure.TABLE_NAME
				   AND COLUMNS.COLUMN_NAME = SourceStructure.COLUMN_NAME 
WHERE (
		COLUMNS.TABLE_SCHEMA LIKE ' + QUOTENAME(@schema_name_LIKE, '''') + '
		  AND COLUMNS.TABLE_NAME LIKE ' + QUOTENAME(@table_name_LIKE, '''') + '
		AND COLUMNS.COLUMN_NAME LIKE ' + QUOTENAME(@column_name_LIKE, '''')
      + ')
		OR
		  SourceStructure.TABLE_SCHEMA LIKE ' + QUOTENAME(@schema_name_LIKE, '''') + '
		  AND SourceStructure.TABLE_NAME LIKE ' + QUOTENAME(@table_name_LIKE, '''') + '
		  AND SourceStructure.COLUMN_NAME LIKE ' + QUOTENAME(@column_name_LIKE, '''')
      + ')

SELECT CASE WHEN Target_TABLE_SCHEMA IS NULL AND TABLE_SCHEMA IS NOT NULL THEN ''Missing Column/Table''
			WHEN Target_TABLE_SCHEMA IS NOT NULL AND TABLE_SCHEMA IS NULL THEN ''Extra Column/Table''
				WHEN Target_DATA_TYPE <> DATA_TYPE THEN ''Different Datatype''
				WHEN Target_IS_NULLABLE <> IS_NULLABLE THEN ''Different Nullability''
			WHEN Target_CHARACTER_MAXIMUM_LENGTH <> CHARACTER_MAXIMUM_LENGTH THEN ''Different Character Length''
			WHEN Target_NUMERIC_PRECISION <> NUMERIC_PRECISION THEN ''Different Numeric Precision''
			WHEN Target_NUMERIC_PRECISION_RADIX <> NUMERIC_PRECISION_RADIX THEN ''Different Numeric Precision Radix''
			WHEN Target_NUMERIC_SCALE <> NUMERIC_SCALE THEN ''Different Numeric Scale''
			WHEN Target_DATETIME_PRECISION <> DATETIME_PRECISION THEN ''Different Date Precision''
			ELSE ''Mismatch in column configuration''
		 END AS Issue, 
		 COALESCE(Target_TABLE_SCHEMA,TABLE_SCHEMA) AS TABLE_SCHEMA, 
		 COALESCE(Target_TABLE_NAME,TABLE_NAME) AS TABLE_NAME,
		 COALESCE(Target_COLUMN_NAME, COLUMN_NAME) AS COLUMN_NAME,

         FormatLayer.DATA_TYPE,
         FormatLayer.Target_DATA_TYPE,

		 FormatLayer.IS_NULLABLE,
         FormatLayer.Target_IS_NULLABLE,

		 FormatLayer.CHARACTER_MAXIMUM_LENGTH,
		 FormatLayer.Target_CHARACTER_MAXIMUM_LENGTH,

         FormatLayer.DATETIME_PRECISION,
         FormatLayer.Target_DATETIME_PRECISION,

         FormatLayer.NUMERIC_SCALE,
         FormatLayer.Target_NUMERIC_SCALE,

         FormatLayer.NUMERIC_PRECISION,
         FormatLayer.Target_NUMERIC_PRECISION,
         
         FormatLayer.NUMERIC_PRECISION_RADIX,
         FormatLayer.Target_NUMERIC_PRECISION_RADIX

FROM	FormatLayer
WHERE	Target_TABLE_SCHEMA IS NULL AND TABLE_SCHEMA IS NOT NULL
		OR Target_TABLE_SCHEMA IS NOT NULL AND TABLE_SCHEMA IS NULL
		OR Target_TABLE_NAME <> TABLE_NAME
		OR Target_COLUMN_NAME <> COLUMN_NAME
		OR Target_DATA_TYPE <> DATA_TYPE
		OR Target_IS_NULLABLE <> IS_NULLABLE
		OR Target_CHARACTER_MAXIMUM_LENGTH <> CHARACTER_MAXIMUM_LENGTH
		OR Target_NUMERIC_PRECISION <> NUMERIC_PRECISION
		OR Target_NUMERIC_PRECISION_RADIX <> NUMERIC_PRECISION_RADIX
		OR Target_NUMERIC_SCALE <> NUMERIC_SCALE
		OR Target_DATETIME_PRECISION <> DATETIME_PRECISION
ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME;

IF @@Rowcount > 0
	RAISERROR (''The comparison failed on the columns of the table. Differences show in results preceding'',16,1);
';

SELECT @SQLQUERY;
