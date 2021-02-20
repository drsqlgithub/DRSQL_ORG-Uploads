--==2005 and later	

--Add extended property
EXEC sys.sp_addextendedproperty @name =N'<PropertyName>',
                                @value =N'<PropertyValue>'


c



--View all database properties
SELECT *
FROM sys.extended_properties
WHERE class_desc ='DATABASE'

--Remove extended property
EXEC sys.sp_dropextendedproperty@name = N'<PropertyName>'

--== Schema Level	

--2005 and later  	

--Add the property to the schema
EXEC sys.sp_addextendedproperty @name =N'<PropertyName>',
                                @value =N'<PropertyValue>',
                                @level0Type = 'Schema',
                                @level0Name = '<SchemaName>'

--View all schema properties
SELECT SCHEMA_NAME(major_id) AS schema_name, name, value
FROM sys.extended_properties 
WHERE class_desc = 'SCHEMA' 

--Remove a schema property
EXEC sys.sp_dropextendedproperty @name =N'<PropertyName>',
                                 @level0Type = 'Schema',
                                 @level0Name = '<SchemaName>'
 
--==Table Level	 

--2005 and later	 

--Add the property to the table
EXEC sys.sp_addextendedproperty @name =N'<PropertyName>',
                                @value =N'<PropertyValue>',
                                @level0Type = 'Schema',
                                @level0Name = '<SchemaName>',
                                @level1Type = 'Table',
                                @level1Name = '<TableName>'

--View all table properties
SELECT OBJECT_SCHEMA_NAME(major_id) AS schema_name, 
       OBJECT_NAME(major_id) AS table_name, name, value
FROM   sys.extended_properties 
WHERE  class_desc = 'OBJECT_OR_COLUMN' 
  AND  minor_id = 0
  AND  OBJECTPROPERTY(major_ID,'istable') = 1
 
--Remove the property
EXEC sys.sp_addextendedproperty @name =N'<PropertyName>',
                                @level0Type = 'Schema',
                                @level0Name = '<SchemaName>',
                                @level1Type = 'Table',
                                @level1Name = '<TableName>'
--==Column Level	

--2005 and later	

--Add the property to the column
EXEC sys.sp_addextendedproperty @name =N'<PropertyName>',
                                @value =N'<PropertyValue>',
                                @level0Type = 'Schema',
                                @level0Name = '<SchemaName>',
                                @level1Type = 'Table',
                                @level1Name = '<TableName>',
                                @level2Type = 'Column',
                                @level2Name = '<ColumnName>'        

--View all column properties
SELECT OBJECT_SCHEMA_NAME(major_id) AS schema_name,
       OBJECT_NAME(major_id) AS table_name,
       columns.name AS column_name,
       extended_properties.name,
       extended_properties.value
FROM   sys.extended_properties
         JOIN sys.columns
             ON columns.OBJECT_ID = extended_properties.major_id
                AND columns.column_id = extended_properties.minor_id
WHERE  extended_properties.class_desc = 'OBJECT_OR_COLUMN'   
  AND  extended_properties.minor_id <> 0
  AND  OBJECTPROPERTY(extended_properties.major_ID,'istable') = 1
 
--Add the property to the schema
EXEC sys.sp_dropextendedproperty @name =N'<PropertyName>',
                                 @level0Type = 'Schema',
                                 @level0Name = '<SchemaName>',
                                 @level1Type = 'Table',
                                 @level1Name = '<TableName>',
                                 @level2Type = 'Column',
                                 @level2Name = '<ColumnName>'