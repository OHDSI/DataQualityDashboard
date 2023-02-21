
/*********
Table Level:  
MEASURE_CONCEPT_COMPLETENESS
Determine what #/% of records have at least one our source_concept or standard_concept record populated with value>0

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
cdmSourceFieldName = @cdmSourceFieldName
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
FROM
(
	SELECT 
		COUNT_BIG(*) AS num_violated_rows
	FROM
	(
		/*violatedRowsBegin*/
		SELECT 
			cdmTable.* 
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
			{@cohort & '@runForCohort' == 'Yes'}?{
    		JOIN @cohortDatabaseSchema.cohort c 
    		ON cdmTable.person_id = c.subject_id
    		AND c.cohort_definition_id = @cohortDefinitionId
    	}
		WHERE (cdmTable.@cdmFieldName = 0 OR cdmTable.@cdmFieldName IS NULL)
			AND (cdmTable.@cdmSourceFieldName = 0 OR cdmTable.@cdmSourceFieldName IS NULL)
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
) denominator
;
