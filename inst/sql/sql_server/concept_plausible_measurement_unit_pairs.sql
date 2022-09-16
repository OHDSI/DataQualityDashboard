/*********
CONCEPT LEVEL check:
PLAUSIBLE_MEASUREMENT_UNIT_PAIRS - find any MEASUREMENT records that are associated with an incorrect UNIT_CONCEPT_ID

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
conceptId = @conceptId
plausibleMeasurementUnitPairs = @plausibleMeasurementUnitPairs
{@cohort}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
}
**********/


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT COUNT_BIG(*) AS num_violated_rows
	FROM
	(
		/*violatedRowsBegin*/
		SELECT m.* 
		FROM @cdmDatabaseSchema.@cdmTableName m
		{@cohort}?{
  	JOIN @cohortDatabaseSchema.COHORT c
  	ON m.PERSON_ID = c.SUBJECT_ID
  	AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
  	}
		WHERE m.@cdmFieldName = @conceptId
		AND {@plausibleMeasurementUnitPairs == ''}?{
		  m.unit_concept_id IS NOT NULL
		}:{
		  m.unit_concept_id NOT IN (@plausibleMeasurementUnitPairs)
		}
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName m
	{@cohort}?{
	JOIN @cohortDatabaseSchema.COHORT c
	ON m.PERSON_ID = c.SUBJECT_ID
	AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
	}
	WHERE m.@cdmFieldName = @conceptId
) denominator
;