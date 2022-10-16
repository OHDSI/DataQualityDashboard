/*********
CONCEPT_RECORD_COMPLETENESS
number of 0s / total number of records {@cdmTableName == 'OBSERVATION' | @cdmTableName == 'MEASUREMENT'}?{* for the OBSERVATION.unit_concept_id and MEASUREMENT.unit_concept_id the numerator and denominator are limited to records where value_as_number IS NOT NULL}

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
{@cohort & '@runForCohort' == 'Yes'}?{
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
FROM (
	SELECT 
	  COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM (
		/*violatedRowsBegin*/
		SELECT 
		  '@cdmTableName.@cdmFieldName' AS violating_field, 
		  cdmTable.* 
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
  		{@cohort & '@runForCohort' == 'Yes'}?{
      	JOIN @cohortDatabaseSchema.cohort c
      	ON cdmTable.person_id = c.subject_id
      	AND c.cohort_definition_id = @cohortDefinitionId
    	}
		WHERE cdmTable.@cdmFieldName = 0 {@cdmFieldName == 'UNIT_CONCEPT_ID' & (@cdmTableName == 'MEASUREMENT' | @cdmTableName == 'OBSERVATION')}?{AND cdmTable.value_as_number IS NOT NULL}
		/*violatedRowsEnd*/
		) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
	  {@cohort & '@runForCohort' == 'Yes'}?{
    	JOIN @cohortDatabaseSchema.cohort c
    	ON cdmTable.person_id = c.subject_id
    	AND c.cohort_definition_id = @cohortDefinitionId
  	}
	{@cdmFieldName == 'UNIT_CONCEPT_ID' & (@cdmTableName == 'MEASUREMENT' | @cdmTableName == 'OBSERVATION')}?{WHERE cdmTable.value_as_number IS NOT NULL}
) denominator
;
