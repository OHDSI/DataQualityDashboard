
/*********
FIELD_CDM_DATATYPE

At a minimum, for each field that is supposed to be an integer, verify it is an integer

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
**********/


SELECT 
  num_violated_rows, 
	CASE 
		WHEN denominator.num_rows = 0 THEN 0 
		ELSE 1.0*num_violated_rows/denominator.num_rows 
	END AS pct_violated_rows, 
	denominator.num_rows AS num_denominator_rows
FROM
(
	SELECT 
	  COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		/*violatedRowsBegin*/
		SELECT 
		  '@cdmTableName.@cdmFieldName' AS violating_field, 
		  cdmTable.* 
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		WHERE 
		  (ISNUMERIC(cdmTable.@cdmFieldName) = 0 
		    OR (ISNUMERIC(cdmTable.@cdmFieldName) = 1 
		      AND CHARINDEX('.', CAST(ABS(cdmTable.@cdmFieldName) AS varchar)) != 0))
      AND cdmTable.@cdmFieldName IS NOT NULL
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
( 
	SELECT 
	  COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;
