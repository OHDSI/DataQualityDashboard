
/*********
PLAUSIBLE_DURING_LIFE
get number of events that occur after death event (PLAUSIBLE_DURING_LIFE == Yes)

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
**********/


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows
FROM
(
	SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.*
    from @cdmDatabaseSchema.@cdmTableName
    join @cdmDatabaseSchema.death 
      on @cdmDatabaseSchema.@cdmTableName.person_id = @cdmDatabaseSchema.death.person_id
    {@cohort & '@runForCohort' == 'Yes'}?{
    	JOIN @cohortDatabaseSchema.COHORT 
    	ON @cdmTableName.PERSON_ID = COHORT.SUBJECT_ID
    	AND COHORT.COHORT_DEFINITION_ID = @cohortDefinitionId
    	}
    where @cdmFieldName > dateadd(day,60,death_date) 
	) violated_rows
) violated_row_count,
(
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
	{@cohort & '@runForCohort' == 'Yes'}?{
	JOIN @cohortDatabaseSchema.COHORT 
	ON @cdmTableName.PERSON_ID = COHORT.SUBJECT_ID
	AND COHORT.COHORT_DEFINITION_ID = @cohortDefinitionId
	}
	where @cdmTableName.person_id in
	( select person_id from @cdmDatabaseSchema.death )
) denominator
;
