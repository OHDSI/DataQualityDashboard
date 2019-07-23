
/*********
FIELD_FK_DOMAIN

all standard concept ids are part of specified domain

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
domain = @domain
**********/

SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows
FROM
(
	SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, t.* 
		  FROM @cdmDatabaseSchema.@cdmTableName t
		  JOIN @cdmDatabaseSchema.CONCEPT c
		    ON t.@cdmFieldName = c.CONCEPT_ID
		 WHERE t.DOMAIN_ID = '@domain'
           AND t.DOMAIN_ID != c.DOMAIN_ID 		 
		  
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;