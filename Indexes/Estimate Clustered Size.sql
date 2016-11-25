DECLARE  
--Specify the number of rows that will be present in the table
		 @num_rows BIGINT = 554803678
--Specify the number of fixed-length and variable-length columns and calculate the space that is required for their storage
		,@num_cols BIGINT = 1
		,@Fixed_Data_Size BIGINT = 8
		,@Num_Variable_Cols BIGINT= 0
		,@Max_Var_Size BIGINT = 0
--Index fill factor
		,@Fill_Factor BIGINT = 100


DECLARE @Null_Bitmap BIGINT = FLOOR(2 + ((@num_cols + 7) / 8))

DECLARE @Variable_Data_Size BIGINT = 0 --If there are variable-leght: 2 + (@Num_Variable_Cols * 2) + @Max_Var_Size


DECLARE @Row_Size BIGINT = @Fixed_Data_Size + @Variable_Data_Size + @Null_Bitmap + 4 --The value 4 is the row header overhead of a data row

DECLARE @Rows_Per_Page BIGint = FLOOR(8096 / (@Row_Size + 2))
--Calculate the number of reserved free rows per page, based on the fill factor specified:
DECLARE @Free_Rows_Per_Page BIGINT = FLOOR(8096 * ((100 - @Fill_Factor) / 100) / (@Row_Size + 2))
--Calculate the number of pages required to store all the rows
DECLARE @Num_Leaf_Pages BIGINT = CEILING(@num_rows / (@Rows_Per_Page - @Free_Rows_Per_Page))
--Calculate the amount of space that is required to store the data in the leaf level (8192 total bytes per page)
DECLARE @Leaf_space_used BIGINT = 8192 * @Num_Leaf_Pages


--Specify the number of fixed-length and variable-length columns in the index key and calculate the space that is required for their storage
--Account for any uniqueifier needed if the index is nonunique
DECLARE  @Num_Key_Cols  BIGINT = 1
		,@Fixed_Key_Size  BIGINT = 8
		,@Num_Variable_Key_Cols BIGINT = 0
		,@Max_Var_Key_Size BIGINT = 0
--Calculate the null bitmap size
DECLARE  @Index_Null_Bitmap BIGINT = 0 --If there are nullable keys: 2 + ((number of columns in the index row + 7) / 8)
		,@Variable_Key_Size BIGINT = 0 --If variable-lenght columns  2 + (Num_Variable_Key_Cols x 2) + Max_Var_Key_Size

DECLARE @Index_Row_Size BIGINT = @Fixed_Key_Size + @Variable_Key_Size + @Index_Null_Bitmap 
								+ 1 --(for row header overhead of an index row) 
								+ 6 --(for the child page ID pointer)

--Calculate the number of index rows per page (8096 free bytes per page):
DECLARE @Index_Rows_Per_Page BIGINT = FLOOR(8096 / (@Index_Row_Size + 2))
--Calculate the number of levels in the index
DECLARE @Non_leaf_Levels BIGINT = CEILING(1 + log((@Num_Leaf_Pages / @Index_Rows_Per_Page), @Index_Rows_Per_Page))
--Calculate the number of non-leaf pages in the index
--Num_Index_Pages = ∑Level (Num_Leaf_Pages / (Index_Rows_Per_Page**Level))
DECLARE @Num_Index_Pages BIGINT --?Level (@Num_Leaf_Pages / (@Index_Rows_Per_Page))


;WITH n(n) AS
(
    SELECT 1
    UNION ALL
    SELECT n+1 
	FROM n WHERE n <= @Non_leaf_Levels
)
SELECT @Num_Index_Pages=SUM(ROUND(@Num_Leaf_Pages / POWER(@Index_Rows_Per_Page,n),0)) 
FROM n 
OPTION (MAXRECURSION 0);

--Calculate the size of the index (8192 total bytes per page)
DECLARE @Index_Space_Used INT = 8192 * @Num_Index_Pages


SELECT (@Leaf_Space_Used + @Index_Space_used ) / 1024.00  AS [Clustered index size (kb)] 
		,(@Leaf_Space_Used + @Index_Space_used ) / 1024 /1024.00 AS [Clustered index size (mb)] 
		,(@Leaf_Space_Used + @Index_Space_used ) / 1024 /1024 / 1024.00 AS [Clustered index size (gb)] 