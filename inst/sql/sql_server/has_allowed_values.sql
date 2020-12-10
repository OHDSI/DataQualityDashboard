
/*********
CONCEPT LEVEL check:
PLAUSIBLE VALUES - number of records of a given concept which have a value in another field that is not in the conventions

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
conceptId = @conceptId
cdmValueFieldName = @cdmValueFieldName
plausibleValues = @plausibleValues
**********/


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT COUNT_BIG(*) AS num_violated_rows
	FROM
	(
		SELECT cdmTable.* 
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		WHERE cdmTable.@cdmFieldName = @conceptId
		AND cdmTable.@cdmValueFieldName not in @plausibleValues
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
	WHERE @cdmFieldName = @conceptId 
) denominator
;