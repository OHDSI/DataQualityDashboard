
/*********
FIELD_IS_STANDARD_VALID_CONCEPT

all standard concept id fields are standard and valid

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
**********/

SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows
FROM
(
	SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.* 
		  FROM @cdmDatabaseSchema.@cdmTableName
		 WHERE @cdmTableName.@cdmFieldName IN ( SELECT t.@cdmFieldName 
		                                          FROM @cdmDatabaseSchema.@cdmTableName t   
												  LEFT JOIN @cdmDatabaseSchema.CONCEPT c
												    ON t.@cdmFieldName = c.CONCEPT_ID 
											     WHERE c.CONCEPT_ID != 0 AND (c.STANDARD_CONCEPT != 'S' OR c.INVALID_REASON IS NOT NULL ) 
	  ) 
  ) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;