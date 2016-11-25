--Objects w/either ansi_nulls | quoted_identifier
SELECT  OBJECT_NAME([object_id])
       ,uses_ansi_nulls
       ,uses_quoted_identifier--,* 
FROM    sys.sql_modules
WHERE   uses_ansi_nulls = 0
        OR uses_quoted_identifier = 0;


--Objects w/ both ansi_nulls & quoted_identifier
SELECT  OBJECT_NAME([object_id])
       ,uses_ansi_nulls
       ,uses_quoted_identifier--,* 
FROM    sys.sql_modules
WHERE   uses_ansi_nulls = 1
        AND uses_quoted_identifier = 1;