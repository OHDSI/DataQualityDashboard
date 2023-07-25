
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
cohortTableName = @cohortTableName
}
**********/


INSERT INTO @captureDatabaseSchema.@cdmTableName
SELECT 
  cdmTable.*,
  '@cdmFieldName_plausible_during_life' DQ_CHECK_NAME
FROM @cdmDatabaseSchema.@cdmTableName cdmTable
	{@cohort & '@runForCohort' == 'Yes'}?{
		JOIN @cohortDatabaseSchema.@cohortTableName c ON cdmTable.person_id = c.subject_id
			AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
	}
JOIN @cdmDatabaseSchema.death de ON cdmTable.person_id = de.person_id
WHERE cast(cdmTable.@cdmFieldName AS DATE) > DATEADD(day, 60, cast(de.death_date AS DATE))
;
