/*********
Table Level:
MEASURE_VISIT_DATETIME_COMPLETENESS
Determine what #/% of visits have legitimate timestamps
rather than date only information

Parameters used in this template:
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
		SELECT person_id
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		{@cohort & '@runForCohort' == 'Yes'}?{
    		JOIN @cohortDatabaseSchema.@cohortTableName c
    		    ON co.person_id = c.subject_id
    		    AND c.cohort_definition_id = @cohortDefinitionId
    	}
        WHERE (visit_start_datetime IS NULL
            OR visit_end_datetime IS NULL
            OR CAST(CONCAT(
                visit_start_date,
                ' 00:00:00'
            ) AS TIMESTAMP) = visit_start_datetime
            OR CAST(CONCAT(
                visit_end_date,
                ' 00:00:00'
            ) AS TIMESTAMP) = visit_end_datetime)
            AND visit_concept_id IN (262, 9201, 8717, 32037, 581383, 581379)
	) violated_rows
) violated_row_count,
(
	SELECT
		COUNT_BIG(person_id) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		{@cohort & '@runForCohort' == 'Yes'}?{
    		JOIN @cohortDatabaseSchema.@cohortTableName c
    		    ON co.person_id = c.subject_id
    		    AND c.cohort_definition_id = @cohortDefinitionId
    	}
    WHERE visit_concept_id IN (262, 9201, 8717, 32037, 581383, 581379)
) denominator
;
