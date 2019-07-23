
/*********
IS_FOREIGN_KEY
Foreign key check

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
fkTableName = @fkTableName
fkFieldName = @fkFieldName
**********/


SELECT num_violated_rows, 1.0*num_violated_rows/denominator.num_rows AS pct_violated_rows
FROM
(
	SELECT COUNT(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.* 
		FROM @cdmDatabaseSchema.@cdmTableName
		LEFT JOIN @cdmDatabaseSchema.@fkTableName 
		ON @cdmTableName.@cdmFieldName = @fkTableName.@fkFieldName
		WHERE @fkTableName.@fkFieldName IS NULL
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;