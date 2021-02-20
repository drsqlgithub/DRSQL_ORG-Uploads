Will not install any modules in your database. Used to query metadata, performance, or some aspect of the system.

 	 
Column Metadata - ColumnMetaDataQuery.sql
A more clear version of column metadata that you can find in  INFORMATION_SCHEMA, 
started primarily to get the datatype declaration, plus the base datatype for alias types.

Database File Sizing - DatabaseFilesSizing.sql 
Lists all of the files on the server and groups them by database. Includes the file type and file name as well
 
Database Filegroup Sizing - FilegroupFileSizing.sql 
Limited to one database, groups files by filegroups, including the file type and filename as well


Identity Table Queries - IdentityTableQueries.sql 
Queries to interrogate the structure of the tables in the database to see how identity columns are being used. Examples are looking for tables with an identity key as the only key, in the primary key with another column, tables without an identity key, and several other scenarios.
 	
Server process list - Dynamic management view query of the current processes on the server