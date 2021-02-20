IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Utility')
	EXEC ('CREATE SCHEMA [Utility]'); 
GO
CREATE OR ALTER PROCEDURE [Utility].foreignKey$List
    @referenced_schema_name  sysname = '%',
    @referenced_table_name   sysname = '%',
    @referencing_schema_name sysname = '%',
    @referencing_table_name  sysname = '%'
AS
-----------------------------------------------------------------------------------------------
--	Used to give you a list of the foreign key constraints that reference and/or are referenced
--  by another table.
--
--  Louis Davidson   drsql.org
------------------------------------------------------------------------------------------------
SELECT foreign_keys.name,
       OBJECT_SCHEMA_NAME(referenced.object_id) + '.' + OBJECT_NAME(referenced.object_id) AS referenced_table_name,
       referenced.name AS referenced_column_name,
       OBJECT_SCHEMA_NAME(referencing.object_id) + '.' + OBJECT_NAME(referencing.object_id) AS referencing_table_name,
       referencing.name AS referencing_column_name
FROM   sys.foreign_keys
       JOIN sys.foreign_key_columns
            JOIN sys.columns AS referencing --columns of the table that are part of the child table
                ON referencing.object_id = foreign_key_columns.parent_object_id
                    AND referencing.column_id = foreign_key_columns.parent_column_id
            JOIN sys.columns AS referenced --the table that is referenced in the FK
                ON referenced.object_id = foreign_key_columns.referenced_object_id
                    AND referenced.column_id = foreign_key_columns.referenced_column_id
           ON foreign_keys.object_id = foreign_key_columns.constraint_object_id
WHERE  OBJECT_SCHEMA_NAME(referenced.object_id) LIKE @referenced_schema_name
    AND OBJECT_NAME(referenced.object_id) LIKE @referenced_table_name
    AND OBJECT_SCHEMA_NAME(referencing.object_id) LIKE @referencing_schema_name
    AND OBJECT_NAME(referencing.object_id) LIKE @referencing_table_name;
GO