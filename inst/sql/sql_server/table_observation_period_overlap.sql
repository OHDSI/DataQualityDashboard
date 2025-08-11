/*********
Table Level:  
MEASURE_OBSERVATION_PERIOD_OVERLAP
Determine what #/% of persons have overlapping or back-to-back observation periods

Parameters used in this template:
schema = @schema
cdmTableName = @cdmTableName
{@cohort & '@runForCohort' == 'Yes'}?{
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
		COUNT_BIG(violated_rows.person_id) AS num_violated_rows
	FROM
	(
		/*violatedRowsBegin*/
		SELECT DISTINCT
			cdmTable.person_id 
		FROM @cdmDatabaseSchema.observation_period cdmTable
		{@cohort & '@runForCohort' == 'Yes'}?{
    		JOIN @cohortDatabaseSchema.@cohortTableName c 
    		    ON cdmTable.person_id = c.subject_id
    		    AND c.cohort_definition_id = @cohortDefinitionId
    	}
		JOIN @cdmDatabaseSchema.observation_period cdmTable2 
		    ON cdmTable.person_id = cdmTable2.person_id
		    AND cdmTable.observation_period_id != cdmTable2.observation_period_id
		WHERE (cdmTable.observation_period_start_date <= cdmTable2.observation_period_end_date 
		    AND cdmTable.observation_period_end_date >= cdmTable2.observation_period_start_date)
		    OR (DATEADD(day, 1, cdmTable.observation_period_end_date) = cdmTable2.observation_period_start_date)
		    OR (DATEADD(day, 1, cdmTable2.observation_period_end_date) = cdmTable.observation_period_start_date)
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
( 
	SELECT 
		COUNT_BIG(DISTINCT cdmTable.person_id) AS num_rows
	FROM @cdmDatabaseSchema.observation_period cdmTable
	{@cohort & '@runForCohort' == 'Yes'}?{
    	JOIN @cohortDatabaseSchema.@cohortTableName c 
    	    ON cdmTable.person_id = c.subject_id
    	    AND c.cohort_definition_id = @cohortDefinitionId
    }
) denominator
;
