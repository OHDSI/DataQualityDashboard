
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


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, A.* 
		FROM @cdmDatabaseSchema.@cdmTableName A
		LEFT JOIN @cdmDatabaseSchema.@fkTableName B
		ON A.@cdmFieldName = B.@fkFieldName
		WHERE B.@fkFieldName IS NULL AND A.@cdmFieldName IS NOT NULL 
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;