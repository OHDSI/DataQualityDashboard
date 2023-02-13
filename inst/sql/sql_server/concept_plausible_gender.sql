
/*********
CONCEPT LEVEL check:
PLAUSIBLE_GENDER - number of records of a given concept which occur in person with implausible gender for that concept

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
conceptId = @conceptId
plausibleGender = @plausibleGender
{@cohort}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
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
		SELECT cdmTable.* 
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
			INNER JOIN @cdmDatabaseSchema.person p
			ON cdmTable.person_id = p.person_id
			{@cohort}?{
      	JOIN @cohortDatabaseSchema.cohort c
      	  ON cdmTable.person_id = c.subject_id
      	  AND c.cohort_definition_id = @cohortDefinitionId
    	}
		WHERE cdmTable.@cdmFieldName = @conceptId
		  AND p.gender_concept_id <> {@plausibleGender == 'Male'} ? {8507} : {8532} 
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
( 
	SELECT 
	  COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
  	{@cohort}?{
    	JOIN @cohortDatabaseSchema.cohort c
      	ON cdmTable.person_id = c.subject_id
      	AND c.cohort_definition_id = @cohortDefinitionId
  	}
	WHERE @cdmFieldName = @conceptId
) denominator
;
