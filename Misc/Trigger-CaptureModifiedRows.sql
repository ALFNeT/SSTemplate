DECLARE @i AS INT,
    @num_cols AS INT;
DECLARE @UpdCols TABLE
(
 ordinal_position INT NOT NULL
                      PRIMARY KEY
);

SET @num_cols = (
                 SELECT COUNT(*)
                 FROM   INFORMATION_SCHEMA.COLUMNS
                 WHERE  TABLE_SCHEMA = '<schema_name>'
                        AND TABLE_NAME = '<table_name>'
                );

SET @i = 1;
WHILE @i <= @num_cols
    BEGIN
        IF (SUBSTRING(COLUMNS_UPDATED(), (@i - 1) / 8 + 1, 1)) & POWER(2, (@i - 1) % 8) = POWER(2, (@i - 1) % 8)
            INSERT  INTO @UpdCols
            VALUES  (@i);
        SET @i = @i + 1;
    END;

DECLARE @tableCols TABLE
(
 column_name NVARCHAR(128)
);
INSERT  INTO @tableCols
        (
         column_name
        )
SELECT  C.COLUMN_NAME AS updated_column
FROM    INFORMATION_SCHEMA.COLUMNS AS C
JOIN    @UpdCols AS U ON C.ORDINAL_POSITION = U.ordinal_position
WHERE   C.TABLE_SCHEMA = '<schema_name>'
        AND C.TABLE_NAME = '<table_name>'
ORDER BY C.ORDINAL_POSITION;

SELECT  STUFF((
               SELECT   ',' + C.COLUMN_NAME
               FROM     INFORMATION_SCHEMA.COLUMNS AS C
               JOIN     @UpdCols AS U ON C.ORDINAL_POSITION = U.ordinal_position
               WHERE    C.TABLE_SCHEMA = '<schema_name>'
                        AND C.TABLE_NAME = '<table_name>'
              FOR
               XML PATH('')
              ), 1, 1, '') AS cols;
