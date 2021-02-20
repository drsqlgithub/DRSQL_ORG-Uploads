SELECT  --the name of the database
        CASE WHEN GROUPING(DB_NAME(database_id)) = 1 THEN '@TOTAL'
             ELSE DB_NAME(database_id)
        END AS database_name ,

        --the logical name of the file
        CASE WHEN GROUPING(master_files.name) = 1 THEN '@TOTAL'
             ELSE master_files.name
        END AS database_file_name ,

        --the size of the file is stored in # of pages
        SUM(master_files.size * 8.0) AS size_in_kb,
        SUM(master_files.size * 8.0) / 1024.0 AS size_in_mb,
        SUM(master_files.size * 8.0) / 1024.0 / 1024.0 AS size_in_gb,

        --the physical filename only
        CASE WHEN GROUPING(master_files.name) = 1 THEN ''
             ELSE MAX(master_files.type_desc)
        END AS file_type ,  
        
        --the physical filename only
        CASE WHEN GROUPING(master_files.name) = 1 THEN ''
             ELSE MAX(UPPER(SUBSTRING(master_files.physical_name, 1, 1)))
        END AS filesystem_drive_letter ,               


       --thanks to Phillip Kelley from http://stackoverflow.com/questions/1024978/find-index-of-last-occurrence-of-a-sub-string-using-t-sql
       --for the REVERSE code to get the filename and path.

        --the physical filename only
        CASE WHEN GROUPING(master_files.name) = 1 THEN ''
             ELSE MAX(REVERSE(LEFT(REVERSE(master_files.physical_name),
                     CHARINDEX('\', REVERSE(physical_name)) - 1)))
        END AS filesystem_file_name ,

        --the path of the file only
       cASE WHEN GROUPING(master_files.name) = 1 THEN ''
             ELSE MAX(REPLACE(master_files.physical_name,
                REVERSE(LEFT(REVERSE(master_files.physical_name),
                             CHARINDEX('\', REVERSE(physical_name)) - 1)), ''))
             END AS filesystem_path

FROM    sys.master_files 
GROUP BY DB_NAME(database_id) , --the database and filegroup and the file (all of the parts)
         master_files.name WITH rollup
ORDER BY database_name, database_file_name

