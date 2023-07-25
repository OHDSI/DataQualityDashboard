
/*********
PLAUSIBLE_TEMPORAL_AFTER
get number of records and the proportion to total number of eligible records with datetimes that do not occur on or after their corresponding datetimes

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
captureDatabaseSchema = @captureDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
plausibleTemporalAfterTableName = @plausibleTemporalAfterTableName
plausibleTemporalAfterFieldName = @plausibleTemporalAfterFieldName
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
cohortTableName = @cohortTableName
}
**********/

INSERT INTO @captureDatabaseSchema.@cdmTableName
SELECT 
	cdmTable.*
	'@cdmFieldName_plausible_temporal_after' DQ_CHECK_NAME
FROM @cdmDatabaseSchema.@cdmTableName cdmTable
	{@cdmDatabaseSchema.@cdmTableName != @cdmDatabaseSchema.@plausibleTemporalAfterTableName}?{
	JOIN @cdmDatabaseSchema.@plausibleTemporalAfterTableName plausibleTable ON cdmTable.person_id = plausibleTable.person_id}
{@cohort & '@runForCohort' == 'Yes'}?{
		JOIN @cohortDatabaseSchema.@cohortTableName c ON cdmTable.person_id = c.subject_id
			AND c.cohort_definition_id = @cohortDefinitionId
	}
WHERE 
	{'@plausibleTemporalAfterTableName' == 'PERSON'}?{
	COALESCE(
		CAST(plausibleTable.@plausibleTemporalAfterFieldName AS DATE),
		CAST(CONCAT(plausibleTable.year_of_birth,'-06-01') AS DATE)
	) 
}:{
	CAST(cdmTable.@plausibleTemporalAfterFieldName AS DATE)
} > CAST(cdmTable.@cdmFieldName AS DATE)
;
