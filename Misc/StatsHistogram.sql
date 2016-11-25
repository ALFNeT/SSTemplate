CREATE TABLE #tblHistogram
    (vData SQL_VARIANT
    ,range_rows BIGINT
    ,eq_rows BIGINT
    ,distinct_range_rows BIGINT
    ,avg_range_rows BIGINT
    ,actual_eq_rows BIGINT DEFAULT (NULL)
    ,actual_range_rows BIGINT DEFAULT (NULL)); 
GO

CREATE PROCEDURE #spHistogram
    @strTable sysname
   ,@strIndex sysname
AS
DBCC SHOW_STATISTICS(@strTable, @strIndex) WITH HISTOGRAM; 
GO
TRUNCATE TABLE #tblHistogram; 
GO
INSERT  INTO #tblHistogram
        (vData
        ,range_rows
        ,eq_rows
        ,distinct_range_rows
        ,avg_range_rows)
        EXEC #spHistogram
            'SupportCases'
           ,'cix_SupportCases'; 
GO
-- EQ_ROWS 

UPDATE  #tblHistogram
SET     actual_eq_rows = (SELECT    COUNT(*)
                          FROM      SupportCases WITH (NOLOCK)
                          WHERE     ServiceRequestNumber = h.vData)
FROM    #tblHistogram h;
-- RANGE_ROWS 

WITH    BOUNDS(LowerBound, UpperBound)
          AS (SELECT    LAG(vData) OVER (ORDER BY vData) AS [LowerBound]
                       ,vData [UpperBound]
              FROM      #tblHistogram)
    UPDATE  #tblHistogram
    SET     actual_range_rows = ActualRangeRows
    FROM    (SELECT LowerBound
                   ,UpperBound
                   ,(SELECT COUNT(*)
                     FROM   SupportCases WITH (NOLOCK)
                     WHERE  ServiceRequestNumber > LowerBound
                            AND ServiceRequestNumber < UpperBound) AS ActualRangeRows
             FROM   BOUNDS) AS t
    WHERE   vData = t.UpperBound; 
GO
SELECT

/*TOP 10 NEWID(),*/
        vData
       ,eq_rows
       ,actual_eq_rows
       ,range_rowsc
       ,actual_range_rows
FROM    #tblHistogram
WHERE   eq_rows <> actual_eq_rows
        OR range_rows <> actual_range_rows; 
--order by 1 
GO

EXEC dbo.#spHistogram
    @strTable = '<table_name>'
   , -- sysname
    @strIndex = '<index_name>' -- sysname
