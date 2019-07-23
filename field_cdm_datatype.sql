
/*********
FIELD_CDM_DATATYPE

At a minimum, for each field that is supposed to be an integer, verify it is an integer

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
**********/



SELECT num_violated_rows, 1.0*num_violated_rows/denominator.num_rows AS pct_violated_rows
FROM
(
	SELECT COUNT(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.* 
		  FROM @cdmDatabaseSchema.@cdmTableName
		 WHERE ISNUMERIC(@cdmTableName.@cdmFieldName) = 0
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;