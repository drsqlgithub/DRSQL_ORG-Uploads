IF SCHEMA_ID('Monitor') IS NULL
	EXECUTE ('CREATE SCHEMA Monitor;');
GO

CREATE TABLE Utility.ExtendedProperty
(
	schema_name sysname NOT NULL,
	object_name sysname  NOT NULL,
	object_type sysname  NOT NULL,
	property_name sysname  NOT NULL,
	property_value sql_variant NULL,
    CONSTRAINT PKExtendedProperty PRIMARY KEY (schema_name,object_name,property_name)
  , RowStartTime datetime2 GENERATED ALWAYS AS ROW START
  , RowEndTime datetime2 GENERATED ALWAYS AS ROW END
  , PERIOD FOR SYSTEM_TIME (RowStartTime, RowEndTime)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Utility.ExtendedPropertyHistory));
GO

CREATE OR ALTER PROCEDURE Utility.ExtendedProperty$Merge
AS
-- ----------------------------------------------------------------
-- Capture and version (using a temporal table) extended properties in a database
--
-- 2020 Louis Davidson – drsql@hotmail.com – drsql.org
-- ----------------------------------------------------------------
MERGE utility.ExtendedProperty AS Target 
    USING (SELECT schemas.name AS schema_name,  objects.name AS object_name, objects.type_desc AS object_type,
				   extended_properties.name AS property_name, 
				   extended_properties.value AS property_value
			FROM   sys.extended_properties 
					   JOIN sys.objects
						JOIN sys.schemas	
							ON objects.schema_id = schemas.schema_id
					ON objects.object_id = extended_properties.major_id
			WHERE  extended_properties.class_desc = 'OBJECT_OR_COLUMN'
			  AND  extended_properties.minor_id = 0) AS Source
ON Source.schema_name = Target.schema_name
   AND Source.object_name = Target.object_name
   AND Source.property_name = Target.property_name
WHEN MATCHED AND Source.property_value <> Target.property_value 
				 OR (Source.property_value IS NULL AND Target.property_value IS NOT NULL)
				 OR (Source.property_value IS NOT NULL AND Target.property_value IS NULL)
    THEN UPDATE SET Target.property_value = Source.property_value
WHEN NOT MATCHED
    THEN INSERT(schema_name, object_name, object_type, property_name, property_value)
	     VALUES(schema_name, object_name, object_type, property_name, property_value)
WHEN NOT MATCHED BY SOURCE
    THEN DELETE;
GO
