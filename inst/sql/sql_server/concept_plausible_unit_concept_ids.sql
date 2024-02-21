/*********
CONCEPT LEVEL check:
PLAUSIBLE_UNIT_CONCEPT_IDS - find any MEASUREMENT records that are associated with an incorrect UNIT_CONCEPT_ID

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
conceptId = @conceptId
plausibleUnitConceptIds = @plausibleUnitConceptIds
{@cohort}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
cohortTableName = @cohortTableName
}
**********/


SELECT 
  num_violated_rows, 
	CASE 
		WHEN denominator.num_rows = 0 THEN 0 
		ELSE 1.0*num_violated_rows/denominator.num_rows 
	END AS pct_violated_rows, 
	denominator.num_rows AS num_denominator_rows
FROM
(
	SELECT 
	  COUNT_BIG(*) AS num_violated_rows
	FROM
	(
		/*violatedRowsBegin*/
		SELECT 
		  m.* 
		FROM @cdmDatabaseSchema.@cdmTableName m
  		{@cohort}?{
        JOIN @cohortDatabaseSchema.@cohortTableName c
    		ON m.person_id = c.subject_id
    		AND c.cohort_definition_id = @cohortDefinitionId
    	}
		WHERE m.@cdmFieldName = @conceptId
		  	AND COALESCE (m.unit_concept_id, -1) NOT IN (@plausibleUnitConceptIds) -- '-1' stands for the cases when unit_concept_id is null
		  	AND m.value_as_number IS NOT NULL 
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
( 
	SELECT 
	  COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName m
  	{@cohort}?{
    	JOIN @cohortDatabaseSchema.@cohortTableName c
    		ON m.person_id = c.subject_id
    		AND c.cohort_definition_id = @cohortDefinitionId
  	}
	WHERE m.@cdmFieldName = @conceptId
	  	AND value_as_number IS NOT NULL
) denominator
;
