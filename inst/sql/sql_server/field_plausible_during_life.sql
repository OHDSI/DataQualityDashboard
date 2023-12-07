
/*********
PLAUSIBLE_DURING_LIFE
get number of events that occur before birth or after death event (PLAUSIBLE_DURING_LIFE == Yes)
Birthdate is either birth_datetime or composed from year_of_birth, month_of_birth, day_of_birth (taking 1st month/1st day if missing).
Denominator is number of records in the table.

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
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
		COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		/*violatedRowsBegin*/
		SELECT 
			'@cdmTableName.@cdmFieldName' AS violating_field, 
			cdmTable.*
    	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
    		{@cohort & '@runForCohort' == 'Yes'}?{
    			JOIN @cohortDatabaseSchema.@cohortTableName c ON cdmTable.person_id = c.subject_id
    				AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
    		}
    	LEFT JOIN @cdmDatabaseSchema.death de ON cdmTable.person_id = de.person_id
    	JOIN @cdmDatabaseSchema.person p ON cdmTable.person_id = de.person_id
    	WHERE cast(cdmTable.@cdmFieldName AS DATE) > DATEADD(day, 60, cast(de.death_date AS DATE)) OR 
			COALESCE(
				p.birth_datetime, 
				CAST(CONCAT(
					p.year_of_birth, '-',
					COALESCE(p.plausibleTable.month_of_birth, 1), '-',
					COALESCE(p.plausibleTable.day_of_birth, 1)
				) AS DATE)
			) > CAST(cdmTable.@cdmFieldName AS DATE)
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
(
	SELECT 
		COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		{@cohort & '@runForCohort' == 'Yes'}?{
    		JOIN @cohortDatabaseSchema.@cohortTableName c ON cdmTable.person_id = c.subject_id
    			AND c.cohort_definition_id = @cohortDefinitionId
    	}
) denominator
;
