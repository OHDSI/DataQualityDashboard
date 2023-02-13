
/*********
Table Level:  
MEASURE_PERSON_COMPLETENESS
Determine what #/% of persons have at least one record in the cdmTable

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
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
		COUNT_BIG(violated_rows.person_id) AS num_violated_rows
	FROM
	(
		/*violatedRowsBegin*/
		SELECT 
			cdmTable.* 
		FROM @cdmDatabaseSchema.person cdmTable
		  {@cohort & '@runForCohort' == 'Yes'}?{
    		JOIN @cohortDatabaseSchema.cohort c 
    		ON cdmTable.person_id = c.subject_id
    		AND c.cohort_definition_id = @cohortDefinitionId
    	}
			LEFT JOIN @cdmDatabaseSchema.@cdmTableName cdmTable2 
			ON cdmTable.person_id = cdmTable2.person_id
		WHERE cdmTable2.person_id IS NULL
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
( 
	SELECT 
		COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.person cdmTable
		{@cohort & '@runForCohort' == 'Yes'}?{
    	JOIN @cohortDatabaseSchema.cohort c 
    	ON cdmTable.person_id = c.subject_id
    	AND c.cohort_definition_id = @cohortDefinitionId
    }
) denominator
;
