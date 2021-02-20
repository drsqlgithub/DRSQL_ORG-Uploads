SELECT  --the name of the database

               --the name of the filegroup (or Log for the log file, which doesn't have a filegroup)
               CASE WHEN GROUPING(filegroups.name) = 1 THEN '@TOTAL'
                         WHEN filegroups.name IS NULL THEN 'LOGS'
                         ELSE filegroups.name
                END AS filegroup_name ,
        
               --the logical name of the file
               CASE WHEN GROUPING(database_files.name) = 1 THEN '@TOTAL'
                        ELSE database_files.name
               END AS database_file_name ,

               --the size of the file is stored in # of pages
               SUM(database_files.size * 8.0) AS size_in_kb,
               --SUM(database_files.size * 8.0) / 1024.0 AS size_in_mb,
               SUM(database_files.size * 8.0) / 1024.0 / 1024.0 AS size_in_gb,
               
               SUM(FILEPROPERTY(database_files.NAME,'SpaceUsed') * 8.0) AS used_size_in_kb,
               --SUM(FILEPROPERTY(database_files.NAME,'SpaceUsed') * 8.0)/ 1024.0  AS used_size_in_mb,
               SUM(FILEPROPERTY(database_files.NAME,'SpaceUsed') * 8.0) / 1024.0 / 1024.0 AS used_size_in_gb,                              

               SUM((database_files.size - FILEPROPERTY(database_files.NAME,'SpaceUsed')) * 8.0) AS available_size_in_kb,
               --SUM((database_files.size - FILEPROPERTY(database_files.NAME,'SpaceUsed')) * 8.0)/ 1024.0  AS available_size_in_mb,
               SUM((database_files.size - FILEPROPERTY(database_files.NAME,'SpaceUsed')) * 8.0) / 1024.0 / 1024.0 AS available_size_in_gb,   

               SUM(DIVFS.size_on_disk_bytes/1024.0) AS size_on_disk_kb,
               
              --the physical filename only
              CASE WHEN GROUPING(database_files.name) = 1 THEN ''
                        ELSE MAX(database_files.type_desc)
               END AS file_type ,  

               --the physical filename only
               CASE WHEN GROUPING(database_files.name) = 1 THEN ''
                        ELSE MAX(UPPER(SUBSTRING(database_files.physical_name, 1, 1)))
               END AS filesystem_drive_letter ,         
        
              --thanks to Phillip Kelley from http://stackoverflow.com/questions/1024978/find-index-of-last-occurrence-of-a-sub-string-using-t-sql

               --the physical filename only
               CASE WHEN GROUPING(database_files.name) = 1 THEN ''
                         ELSE MAX(REVERSE(LEFT(REVERSE(database_files.physical_name), CHARINDEX('\', REVERSE(database_files.physical_name)) - 1)))
                END AS filesystem_file_name ,

                --the path of the file only
               CASE WHEN GROUPING(database_files.name) = 1 THEN ''
                         ELSE MAX(REPLACE(database_files.physical_name, REVERSE(LEFT(REVERSE(database_files.physical_name),
                                                          CHARINDEX('\', REVERSE(database_files.physical_name)) - 1)), ''))
                END AS filesystem_path
FROM    sys.database_files --use sys.master_files if the database is read only and you want to see the metadata that is the database
             --log files do not have a filegroup
                     LEFT OUTER JOIN sys.filegroups 
                             ON database_files.data_space_id = filegroups.data_space_id
					Left Join sys.dm_io_virtual_file_stats(DB_ID(), DEFAULT) DIVFS
							On database_files.file_id = DIVFS.file_id                         
GROUP BY  filegroups.name ,
                 database_files.name WITH ROLLUP
ORDER BY     --the name of the filegroup (or Log for the log file, which doesn't have a filegroup)
                 CASE WHEN GROUPING(filegroups.name) = 1 THEN '@TOTAL'
                          WHEN filegroups.name IS NULL THEN '@TOTAL-SortAfter'
                          ELSE filegroups.name
                  END, 
                  database_file_name

