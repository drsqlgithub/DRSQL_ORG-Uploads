IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Tools')
	EXECUTE ('CREATE SCHEMA [Tools]');
GO

set nocount on 
go 
create table [Tools].time_of_day 
( 
     time_of_day_key smallint primary key, 
     hour_of_day_24 tinyint,                --0-23, military/European time 
     hour_of_day_12 tinyint,                --1-12, repeating for AM/PM, for us American types 
     am_pm char(2),                         --AM/PM 
     minute_of_hour tinyint,                --the minute of the hour, reset at the top of each hour. 0-59 
     half_hour tinyint,                     --1 or 2, if it is the first or second half of the hour 
     half_hour_of_day tinyint,              --1-24, incremented at the top of each half hour for the entire day 
     quarter_hour tinyint,                  --1-4, for each quarter hour 
     quarter_hour_of_day tinyint,           --1-48, incremented at the tope of each half hour for the entire day 
     string_representation_24 char(5),      --military/European textual representation 
     string_representation_12 char(5)       --12 hour clock representation sans AM/PM 
) 
go 


--digits gives you a set of 10 numbers 0-9 
with digits (i) as( 
        select 1 as i union all select 2 as i union all select 3 union all 
        select 4 union all select 5 union all select 6 union all select 7 
        union all select 8 union all select 9 union all select 0) 
--sequence produces a set of integers from 0 - 9999 
,sequence (i) as ( 
        SELECT D1.i + (10*D2.i) + (100*D3.i) + (1000*D4.i) 
        FROM digits AS D1 CROSS JOIN digits AS D2 CROSS JOIN digits AS D3 CROSS JOIN digits AS D4) 
insert into [Tools].time_of_day(time_of_day_key, hour_of_day_24, hour_of_day_12, am_pm, minute_of_hour, half_hour, half_hour_of_day, 
     quarter_hour, quarter_hour_of_day, string_representation_24, string_representation_12) 

--calculates the different values for the time table 
SELECT i as time_of_day_key 
      ,datepart(hh, dateval) as hour_of_day_24 
      ,datepart(hh, dateval) % 12 + case when datepart(hh, dateval) % 12 = 0 then 12 else 0 end as hour_of_day_12 
      ,case when datepart(hh, dateval) between 0 and 11 then 'AM' else 'PM' end as am_pm 
      ,datepart(mi, dateval) AS minute_of_hour 
      ,((i/30) % 2) + 1  AS half_hour --note, I made these next 4 values 1 based, not 0. So the first half hour is 1, the second is 2 
      ,(i/30) + 1  AS half_hour_of_day  --and for the whole day value, they go from 
      ,((i/15) % 4) + 1     AS quarter_hour 
      ,(i/15) + 1  AS quarter_hour_of_day 
      ,right('0' + cast(datepart(hh, dateval) as varchar(2)),2)+ ':' + right('0' + cast(datepart(mi, dateval) as varchar(2)),2) as string_representation_24 
      ,right('0' + cast(datepart(hh, dateval) % 12 + case when datepart(hh, dateval) % 12 = 0 then 12 else 0 end as varchar(2)),2)+  
                                                                  ':' + right('0' + cast(datepart(mi, dateval) as varchar(2)),2) as string_representation_12 
FROM (    SELECT dateadd(minute,i,'20000101') AS dateVal, i 
        FROM sequence AS sequence 
        WHERE i between 0 and 1439 --number of minutes in a day = 1440  
       ) as dailyMinutes 
Go 

