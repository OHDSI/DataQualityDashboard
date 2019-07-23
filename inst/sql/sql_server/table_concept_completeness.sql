
/*********
Table Level:  
MEASURE_CONCEPT_COMPLETENESS
Determine what #/% of records have at least one our source_concept or standard_concept record populated with value>0

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
cdmSourceFieldName = @cdmSourceFieldName


**********/


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows
FROM
(
	SELECT COUNT_BIG(*) AS num_violated_rows
	FROM
	(
		SELECT * 
		FROM @cdmDatabaseSchema.@cdmTableName 
		WHERE (@cdmTableName.@cdmFieldName = 0 OR @cdmTableName.@cdmFieldName IS NULL)
		AND (@cdmTableName.@cdmSourceFieldName = 0 OR @cdmTableName.@cdmSourceFieldName IS NULL)
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;