
/*********
PLAUSIBLE_DURING_LIFE
get number of events that occur after death event (PLAUSIBLE_DURING_LIFE == Yes)

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
}
**********/


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		/*violatedRowsBegin*/
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, cdmTable.*
    from @cdmDatabaseSchema.@cdmTableName cdmTable
    {@cohort & '@runForCohort' == 'Yes'}?{
    	JOIN @cohortDatabaseSchema.COHORT c 
    	ON cdmTable.PERSON_ID = c.SUBJECT_ID
    	AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
    	}
    join @cdmDatabaseSchema.death de on cdmTable.person_id = de.person_id
    where cast(cdmTable.@cdmFieldName as date) > dateadd(day, 60, cast(de.death_date as date))
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
(
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
	{@cohort & '@runForCohort' == 'Yes'}?{
    	JOIN @cohortDatabaseSchema.COHORT c 
    	ON cdmTable.PERSON_ID = c.SUBJECT_ID
    	AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
    	}
	where person_id in
	( select person_id from @cdmDatabaseSchema.death )
) denominator
;
