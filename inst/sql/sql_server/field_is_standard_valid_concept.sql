
/*********
FIELD_IS_STANDARD_VALID_CONCEPT

all standard concept id fields are standard and valid

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
vocabDatabaseSchema = @vocabDatabaseSchema
**********/



SELECT num_violated_rows, 1.0*num_violated_rows/denominator.num_rows AS pct_violated_rows
FROM
(
	SELECT COUNT(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.* 
		  FROM @cdmDatabaseSchema.@cdmTableName
		 WHERE @cdmTableName.@cdmFieldName IN ( SELECT @cdmTableName.@cdmFieldName 
		                                          FROM @cdmDatabaseSchema.@cdmTableName   
												  JOIN @vocabDatabaseSchema.CONCEPT
												    ON @cdmTableName.@cdmFieldName = CONCEPT.CONCEPT_ID 
											     WHERE CONCEPT.STANDARD_CONCEPT != 'S' OR CONCEPT.INVALID_REASON IS NOT NULL ) 
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;