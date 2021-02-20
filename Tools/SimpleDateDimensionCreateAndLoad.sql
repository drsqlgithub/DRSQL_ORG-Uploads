--The CalendarId is an integer that represents the date in YYYYMMDD format. 
--it allows me to use this AS a key, rather than the date value.
--it doesn't save space, but it doesn't have the time, which can be troublesome
--for using a Calendar table. 

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Tools')
	EXECUTE ('CREATE SCHEMA [Tools]');
GO

CREATE TABLE [Tools].Calendar
(
        CalendarId int NOT NULL CONSTRAINT PKdate_dim PRIMARY KEY ,
        DateValue date NOT NULL CONSTRAINT AKdate_dim__DateValue UNIQUE ,        
        DayName varchar(10) NOT NULL,
        MonthName varchar(10) NOT NULL,
        Year varchar(60) NOT NULL,
        Day tinyint NOT NULL,
        DayOfTheYear smallint NOT NULL,
        Month smallint NOT NULL,
        Quarter tinyint NOT NULL,
        WeekendFlag bit NOT NULL, 
        DayInMonthCount tinyint NOT NULL,

        --start of fiscal year configurable in the load process, currently 
        --only supports fiscal months that match the Calendar months.
        FiscalYear smallint NOT NULL,
        FiscalMonth tinyint NULL,
        FiscalQuarter tinyint NOT NULL, 

        --used to give Relative positioning, such AS the previous 10 months
        --which can be annoying due to month boundries
        RelativeDayCount int NOT NULL,
        RelativeWeekCount int NOT NULL,
        RelativeMonthCount int NOT NULL        
) 
GO
;WITH digits (i) AS (
			SELECT 1 AS I UNION ALL SELECT 2 AS I UNION ALL SELECT 3 UNION ALL
			SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
			UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 0)
	,sequence (i) AS (
			SELECT D1.i + (10*D2.i) + (100*D3.i) + (1000*D4.i) + (10000*D5.i)
			FROM digits AS D1 CROSS JOIN digits AS D2 
			CROSS JOIN digits AS D3 CROSS JOIN digits AS D4
			CROSS JOIN digits AS D5) 
	,dates (newDateValue) AS (
			SELECT DATEADD(day,i,'17530101') AS newDateValue
			FROM sequence
)
INSERT [Tools].Calendar
        (CalendarId ,DateValue ,DayName
        ,MonthName ,Year ,Day
        ,DayOfTheYear ,Month ,Quarter
        ,WeekendFlag ,DayInMonthCount, FiscalYear ,FiscalMonth
        ,FiscalQuarter ,RelativeDayCount,RelativeWeekCount
        ,RelativeMonthCount)
SELECT 
        CAST(convert(varchar(10),dates.newDateValue,112) AS int) AS CalendarId,
        dates.newDateValue AS DateValue,
        DATENAME (dw,dates.newDateValue) AS DayName,
        DATENAME (mm,dates.newDateValue) AS MonthName,
        DATENAME (yy,dates.newDateValue) AS Year,
        DATEPART(day,dates.newDateValue) AS Day,
        DATEPART(dy,dates.newDateValue) AS DayOfTheYear,
        DATEPART(m,dates.newDateValue) AS Month,
        CASE
                WHEN MONTH ( dates.newDateValue) <= 3 THEN 1 
                WHEN MONTH ( dates.newDateValue) <= 6 THEN 2 
                WHEN MONTH ( dates.newDateValue) <= 9 THEN 3 
        ELSE 4 END AS Quarter, 

        CASE WHEN DATENAME (dw,dates.newDateValue) in ('Saturday','Sunday') 
                THEN 1 
                ELSE 0 
        END AS WeekendFlag, 
        ((DATEPART(day,dates.newDateValue) - 1)/ 7) + 1 AS DayInMonthCount,

        ------------------------------------------------
        --the next three blocks ASsume a fiscal year starting in July. 
        --replace if your fiscal periods are different
        ------------------------------------------------
        CASE
                WHEN MONTH(dates.newDateValue) <= 6 
                THEN YEAR(dates.newDateValue) 
                ELSE YEAR(dates.newDateValue) + 1 
        END AS FiscalYear, 

        CASE 
                WHEN MONTH(dates.newDateValue) <= 6 
                THEN MONTH(dates.newDateValue) + 6
                ELSE MONTH(dates.newDateValue) - 6 
         END AS FiscalMonth, 

        CASE 
                WHEN MONTH(dates.newDateValue) <= 3 THEN 3
                WHEN MONTH(dates.newDateValue) <= 6 THEN 4 
                WHEN MONTH(dates.newDateValue) <= 9 THEN 1 
        ELSE 2 END AS FiscalQuarter, 

        ------------------------------------------------
        --END of fiscal quarter = july
        ------------------------------------------------ 

        --these values can be anything, AS long AS they provide contiguous values
        --on year and month boundries
        DATEDIFF(day,'17530101',dates.newDateValue) AS RelativeDayCount,
        DATEDIFF(week,'17530101',dates.newDateValue) AS RelativeWeekCount, 
        DATEDIFF(month,'17530101',dates.newDateValue) AS RelativeMonthCount

from    dates
where  dates.newDateValue between '20000101' and '20200101' --set the date range
order  by DateValue 
go


--The next block can be substituted for the previous text used to set the fiscal period information if you are not using a July fiscal period..

/* 
------------------------------------------------
--the next three blocks can be used for a fiscal year starting in April. 
------------------------------------------------
        CASE 
                WHEN MONTH(dates.newDateValue) <= 3 
                THEN year(dates.newDateValue) 
                ELSE year(dates.newDateValue) + 1 
         END AS FiscalYear, 

        CASE 
                WHEN MONTH(dates.newDateValue) <= 3 
                THEN MONTH(dates.newDateValue) + 9
                ELSE MONTH(dates.newDateValue) - 3 
         END AS FiscalMonth, 

        CASE 
                WHEN MONTH(dates.newDateValue) <= 3 THEN 4
                WHEN MONTH(dates.newDateValue) <= 6 THEN 1 
                WHEN MONTH(dates.newDateValue) <= 9 THEN 2 
        ELSE 3 END AS FiscalQuarter, 

        ------------------------------------------------
        --END of fiscal quarter = april
        ------------------------------------------------ 
*/
