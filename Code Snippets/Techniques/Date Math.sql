--==== Strip Time From Date Value (replace SYSDATETIME() or GETDATE() with the date you are interested in

--2005 and earlier
SELECT DATEADD(DAY, 0, DATEDIFF(DAY, 0, GETDATE()))

--2008 + 
SELECT CAST(SYSDATETIME() as date)

--==First Day of the Month relative to a date value

--ALL versions
SELECT DATEADD(day, 0, DATEDIFF(day, 0, SYSDATETIME() ) - DATEPART(DAY,SYSDATETIME()) + 1)

--==Last Day of the Month relative to a date value

--2005-2008R2
SELECT DATEADD(month, 1, DATEDIFF(day, 0, SYSDATETIME() ) - DATEPART(DAY,SYSDATETIME()) )

--2012 +
SELECT EOMONTH(SYSDATETIME())

SELECT DATEADD(month, 1, DATEDIFF(day, 0, SYSDATETIME() ) - DATEPART(DAY,SYSDATETIME()) )

--==First Day of the Year relative to a date value

--ALL
SELECT DATEADD(day, 0, DATEDIFF(day, 0, SYSDATETIME() ) - DATEPART(dayofyear,SYSDATETIME() ) + 1)

--==Last Day of the Year relative to a date value

--ALL
SELECT DATEADD(year, 1, DATEDIFF(day, 0, SYSDATETIME() ) - DATEPART(dayofyear,SYSDATETIME() ) )

