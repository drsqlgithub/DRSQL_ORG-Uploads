
IF OBJECT_ID('Tools.Number') IS NULL
	CREATE TABLE Tools.Number
	(
		I   int CONSTRAINT PKNumber PRIMARY KEY
	);


--Load it with integers from 0 to 999999:
;WITH digits (I) AS (--set up a set of numbers from 0-9
        SELECT I
        FROM   (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS digits (I))
--builds a table from 0 to 999999
,Integers (I) AS (
       --since you have every combinations of digits, This math turns it 
       --into numbers since every combination of digits is present
        SELECT D1.I + (10*D2.I) + (100*D3.I) + (1000*D4.I) + (10000*D5.I)
               + (100000*D6.I)
        --gives us combinations of every digit
        FROM digits AS D1 CROSS JOIN digits AS D2 CROSS JOIN digits AS D3
                CROSS JOIN digits AS D4 CROSS JOIN digits AS D5
                CROSS JOIN digits AS D6 )
INSERT INTO Tools.Number(I)
SELECT I
FROM   Integers
WHERE  I NOT IN (SELECT I FROM TOols.Number);