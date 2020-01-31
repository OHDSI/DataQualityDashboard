
/*********
Table Level:  
MEASURE_PERSON_COMPLETENESS
Determine what #/% of persons have at least one record in the cdmTable

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName

**********/


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows
FROM
(
	SELECT COUNT_BIG(violated_rows.person_id) AS num_violated_rows
	FROM
	(
		SELECT person.* 
		FROM @cdmDatabaseSchema.person
		LEFT JOIN @cdmDatabaseSchema.@cdmTableName 
		ON person.person_id = @cdmTableName.person_id
		WHERE @cdmTableName.person_id IS NULL
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.person
) denominator
;