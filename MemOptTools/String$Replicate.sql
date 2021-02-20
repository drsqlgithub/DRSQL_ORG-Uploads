IF NOT EXISTS (SELECT * from sys.schemas WHERE name = 'MemOptTools')
	EXCECUTE ('CREATE SCHEMA [MemOptTools];')
GO

CREATE OR ALTER FUNCTION [MemOptTools].String$Replicate
(
    @inputString    nvarchar(1000),
    @replicateCount smallint
)
RETURNS nvarchar(1000)
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH(TRANSACTION ISOLATION LEVEL = SNAPSHOT, 
                  LANGUAGE = N'English')
    DECLARE @i int = 0, @output nvarchar(1000) = '';

    WHILE @i < @replicateCount
    BEGIN
        SET @output = @output + @inputString;
        SET @i = @i + 1;
    END;

    RETURN @output;
END;
GO