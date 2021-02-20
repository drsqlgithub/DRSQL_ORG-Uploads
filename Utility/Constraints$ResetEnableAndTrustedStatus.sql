SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS ( SELECT  *
                FROM    sys.schemas
                WHERE   name = 'Utility' ) 
    EXECUTE ('CREATE SCHEMA [Utility]')
GO
CREATE OR ALTER PROCEDURE [Utility].Constraints$ResetEnableAndTrustedStatus
    (
      @table_name SYSNAME = '%' ,
      @table_schema SYSNAME = '%' ,
      @doFkFlag BIT = 1 ,
      @doCkFlag BIT = 1
    )
AS -- ----------------------------------------------------------------
-- Sets all foreign key and check constraints to enabled and trusted
-- if possible
--
-- Note: executes without throwing an error if a constraint doesn't work
-- Return value = -100 if an error occurs...
--
-- 2011 Louis Davidson - drsql.org
-- ----------------------------------------------------------------

    BEGIN
 
        SET nocount ON
        DECLARE @statements CURSOR ,
            @errorFlag BIT 
        SET @errorFlag = 0
        SET @statements = cursor for 
           WITH FKandCHK AS (
				SELECT OBJECT_SCHEMA_NAME(parent_object_id) AS schemaName, 					   OBJECT_NAME(parent_object_id) AS tableName,
					   NAME AS constraintName, Type_desc AS constraintType, is_disabled AS DisabledFlag, 					  (is_not_trusted + 1) % 2 AS TrustedFlag
				FROM   sys.foreign_keys
				UNION ALL 
				SELECT OBJECT_SCHEMA_NAME(parent_object_id) AS schemaName, 					   OBJECT_NAME(parent_object_id) AS tableName,
					   NAME AS constraintName, Type_desc AS constraintType, is_disabled AS DisabledFlag, 					   (is_not_trusted + 1) % 2 AS TrustedFlag
				FROM   sys.check_constraints
				)
				SELECT schemaName, tableName, constraintName, constraintType, disabledFlag, trustedFlag 
				FROM   FKandCHK
				WHERE  (trustedFlag = 0
				  OR   disabledFlag = 1)
				  AND  ((constraintType = 'FOREIGN_KEY_CONSTRAINT' AND @doFkFlag = 1)
				        OR (constraintType = 'CHECK_CONSTRAINT' AND @doCkFlag = 1))
				  AND  schemaName LIKE @table_Schema
				  AND  tableName LIKE @table_Name
				  ORDER BY schemaName, tableName, constraintName

        OPEN @statements

        DECLARE @statement VARCHAR(1000) ,
            @schemaName SYSNAME ,
            @tableName SYSNAME ,
            @constraintName SYSNAME ,
            @constraintType SYSNAME ,
            @disabledFlag BIT ,
            @trustedFlag BIT

        WHILE 1 = 1 
            BEGIN
                FETCH FROM @statements INTO @schemaName, @tableName,
                    @constraintName, @constraintType, @disabledFlag,
                    @trustedFlag 
                IF @@fetch_status <> 0 
                    BREAK

                BEGIN TRY
                    IF @disabledFlag = 1 --go ahead and enable it, even though you may not be able to make it trusted
                        BEGIN
                            SELECT  @statement = 'ALTER TABLE ' + @schemaName
                                    + '.' + @tableName + ' CHECK CONSTRAINT '
                                    + @constraintName
                            EXEC (@statement)
                        END
					  
                    SELECT  @statement = 'ALTER TABLE ' + @schemaName + '.'
                            + @tableName + ' WITH CHECK CHECK CONSTRAINT '
                            + @constraintName
                    EXEC (@statement)
	                
                END TRY
                BEGIN CATCH --informational only, we don't want to stop for an error. Up to caller to check status
                    SELECT  'Error occurred: '
                            + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ':'
                            + ERROR_MESSAGE() + CHAR(13) + CHAR(10)
                            + 'Statement executed: ' + @statement
                    SET @ErrorFlag = 1
                END CATCH

            END
        IF @errorFlag = 1 
            RETURN -100 -- signal to caller that there is something wrong and should be looked at

    END

GO


