-- When using a surrogate key, it is generally a VERY good idea to have an alternate key
-- on the table. Another good idea is to not forget to put the identity column on the table.
-- The following queries are a couple of queries to check the structure of the tables in your
--database. How they are applied will vary by database. These queryies will help you identify 
--how identity columns are used in your database

--identity columns 
SET NOCOUNT ON

SELECT  'Tables with no primary key'

SELECT  schemas.name + '.' + tables.name AS tableName
FROM    sys.tables
		  JOIN sys.schemas
			ON tables.schema_id = schemas.schema_id
WHERE   tables.type_desc = 'USER_TABLE'
--no PK key constraint exists
    AND NOT EXISTS ( SELECT *
                        FROM   sys.key_constraints
                        WHERE  key_constraints.type = 'PK'
                            AND key_constraints.parent_object_id = tables.object_id ) 


SELECT  'Tables with no identity column'

SELECT  schemas.name + '.' + tables.name AS tableName
FROM    sys.tables
		  JOIN sys.schemas
			ON tables.schema_id = schemas.schema_id
WHERE   tables.type_desc = 'USER_TABLE'
--no column in the table has the identity property
    AND NOT EXISTS ( SELECT *
                        FROM   sys.columns
                        WHERE  tables.object_id = columns.object_id
                            AND is_identity = 1 )

SELECT  'Tables with identity column and PK, identity column in AK'

SELECT  schemas.name + '.' + tables.name AS tableName
FROM    sys.tables
		  JOIN sys.schemas
			ON tables.schema_id = schemas.schema_id
WHERE   tables.type_desc = 'USER_TABLE'
	-- table does have identity column
    AND EXISTS (	SELECT *
					FROM   sys.columns
					WHERE  tables.object_id = columns.object_id
						AND is_identity = 1 )
	-- table does have primary key
    AND EXISTS (	SELECT *
                    FROM   sys.key_constraints
                    WHERE  key_constraints.type = 'PK'
                      AND key_constraints.parent_object_id = tables.object_id ) 
	-- but it is not the PK
    AND EXISTS (	SELECT *
                    FROM   sys.key_constraints
                        JOIN sys.index_columns
                            ON index_columns.object_id = key_constraints.parent_object_id
                                AND index_columns.index_id = key_constraints.unique_index_id
                        JOIN sys.columns
                            ON columns.object_id = index_columns.object_id
                                AND columns.column_id = index_columns.column_id
                    WHERE  key_constraints.type = 'UQ'
                        AND key_constraints.parent_object_id = tables.object_id
                        AND columns.is_identity = 1 ) 

SELECT  ' the following tables have an identity based column in the primary key'
        + CHAR(13) + CHAR(10) + ' along with other columns'

SELECT  schemas.name + '.' + tables.name AS tableName
FROM    sys.tables
		  JOIN sys.schemas
			ON tables.schema_id = schemas.schema_id
WHERE   tables.type_desc = 'USER_TABLE'
	--  table does have identity column
    AND EXISTS ( SELECT *
                    FROM   sys.columns
                    WHERE  tables.object_id = columns.object_id
                        AND is_identity = 1 )
	--any PK only has identity column
	AND EXISTS( SELECT    *
			FROM      sys.key_constraints
					JOIN sys.index_columns
						ON index_columns.object_id = key_constraints.parent_object_id
							AND index_columns.index_id = key_constraints.unique_index_id
					JOIN sys.columns
						ON columns.object_id = index_columns.object_id
							AND columns.column_id = index_columns.column_id
			WHERE     key_constraints.type = 'PK'
					AND key_constraints.parent_object_id = tables.object_id
					AND columns.is_identity = 0
		) 
	--and there are > 1 columns in the PK constraint
    AND (  SELECT    COUNT(*)
            FROM    sys.key_constraints
                    JOIN sys.index_columns
                        ON index_columns.object_id = key_constraints.parent_object_id
                            AND index_columns.index_id = key_constraints.unique_index_id
            WHERE     key_constraints.type = 'PK'
                    AND key_constraints.parent_object_id = tables.object_id
        ) > 1








SELECT  ' the following tables have a single column identity based primary key'
        + CHAR(13) + CHAR(10) + ' but no alternate key'

SELECT  schemas.name + '.' + tables.name AS tableName
FROM    sys.tables
		  JOIN sys.schemas
			ON tables.schema_id = schemas.schema_id
WHERE   tables.type_desc = 'USER_TABLE'
	--a PK key constraint exists
	AND EXISTS ( SELECT *
					FROM   sys.key_constraints
					WHERE  key_constraints.type = 'PK'
						AND key_constraints.parent_object_id = tables.object_id ) 
	--any PK only has identity column
	AND ( SELECT    COUNT(*)
			FROM      sys.key_constraints
					JOIN sys.index_columns
						ON index_columns.object_id = key_constraints.parent_object_id
							AND index_columns.index_id = key_constraints.unique_index_id
					JOIN sys.columns
						ON columns.object_id = index_columns.object_id
							AND columns.column_id = index_columns.column_id
			WHERE     key_constraints.type = 'PK'
					AND key_constraints.parent_object_id = tables.object_id
					AND columns.is_identity = 0
		) = 0 --must have > 0 columns in pkey, can only have 1 identity column
	--but no Unique Constraint Exists
	AND NOT EXISTS ( SELECT *
						FROM   sys.key_constraints
						WHERE  key_constraints.type = 'UQ'
							AND key_constraints.parent_object_id = tables.object_id ) 



/*

IF EXISTS (SELECT * FROM sys.tables WHERE object_id = object_id('dbo.NoPrimaryKey')) 
		DROP TABLE dbo.NoPrimaryKey;
IF EXISTS (SELECT * FROM sys.tables WHERE object_id = object_id('dbo.NoIdentityColumn')) 
		DROP TABLE dbo.NoIdentityColumn;
IF EXISTS (SELECT * FROM sys.tables WHERE object_id = object_id('dbo.IdentityButNotInPkey')) 
		DROP TABLE dbo.IdentityButNotInPkey;
IF EXISTS (SELECT * FROM sys.tables WHERE object_id = object_id('dbo.TooManyColumnsInPkey')) 
		DROP TABLE dbo.TooManyColumnsInPkey;
IF EXISTS (SELECT * FROM sys.tables WHERE object_id = object_id('dbo.MultipleColumnsInPkeyOk')) 
		DROP TABLE dbo.MultipleColumnsInPkeyOk;
IF EXISTS (SELECT * FROM sys.tables WHERE object_id = object_id('dbo.NoAlternateKey')) 
		DROP TABLE dbo.NoAlternateKey;
IF EXISTS (SELECT * FROM sys.tables WHERE object_id = object_id('dbo.IdentityInAlternateKey')) 
		DROP TABLE dbo.IdentityInAlternateKey;




--very common scenario, assuming identity makes the table great
CREATE TABLE NoPrimaryKey
(
	NoPrimaryKeyId int not null identity,
	AnotherColumnId int not null 
)
go

--absolutely nothing wrong with this scenario, unless you expect all of your
--tables to have identity columns, of course...
CREATE TABLE NoIdentityColumn
(
	NoIdentityColumnId int primary key,
	AnotherColumnId int not null 
)
go

--absolutely nothing wrong with this scenario either, as this could be desired. 
--usually it is some form of mistake in a database using surrogate keys though
CREATE TABLE IdentityButNotInPkey
(
	IdentityButNotInPkeyId int primary key,
	AnotherColumnId int identity not null 
)
go

--absolutely nothing wrong with this scenario either, as this could be desired. 
--usually it is some form of mistake in a database using surrogate keys though
CREATE TABLE IdentityInAlternateKey
(
	IdentityInAlternateKeyId int primary key,
	AnotherColumnId int identity not null unique
)
go


--In this case, the key columns are illogical. The identity value should always be unique and 
--be a sufficient primary surrogate key. I definitely want to know why this is built this
--way.  Sometimes people with use this for an invoice line item and make the pk the 
--invoiceId and an identity value like invoiceLineItemId. I generally prefer the surrogate key
--to stand alone and have the multi-part key to be something that makes sense for the user
CREATE TABLE TooManyColumnsInSurrogatePkey
(
	TooManyColumnsInPkeyId int identity,
	AnotherColumnId int,
	primary key (TooManyColumnsInPkeyId,AnotherColumnId)
)
go

CREATE TABLE MultipleColumnsInPkeyOk
(
	TooManyColumnsInPkeyId int not null,
	AnotherColumnId int not null,
	primary key (TooManyColumnsInPkeyId,AnotherColumnId)
)
go

--this is my pet peeve, and something that should be avoided. You could end up having
--duplicate rows that are not logical.
CREATE TABLE NoAlternateKey
(
	NoAlternateKeyId int not null identity primary key,
	AnotherColumnThatShouldBeUnique int not null
)
go

*/