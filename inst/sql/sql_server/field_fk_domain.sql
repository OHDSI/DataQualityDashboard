
/*********
FIELD_FK_DOMAIN

all standard concept ids are part of specified domain

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
vocabDatabaseSchema = @vocabDatabaseSchema
domain = @domain
**********/

SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows
FROM
(
	SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.* 
		  FROM @cdmDatabaseSchema.@cdmTableName
		  JOIN @vocabDatabaseSchema.CONCEPT
		    ON @cdmTableName.@cdmFieldName = CONCEPT.CONCEPT_ID
		 WHERE @cdmDatabaseSchema.@cdmTableName.DOMAIN_ID = '@domain'
           AND @cdmDatabaseSchema.@cdmTableName.DOMAIN_ID != CONCEPT.DOMAIN_ID 		 
		  
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;