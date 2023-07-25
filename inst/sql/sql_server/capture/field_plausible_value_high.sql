
/*********
PLAUSIBLE_VALUE_HIGH
get number of records and the proportion to total number of eligible records that exceed this threshold

Parameters used in this template:
schema = @schema
captureDatabaseSchema = @captureDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
plausibleValueHigh = @plausibleValueHigh
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
cohortTableName = @cohortTableName
}
**********/

INSERT INTO @captureDatabaseSchema.@cdmTableName
SELECT 
  cdmTable.*,
  '@cdmFieldName_plausible_value_high' DQ_CHECK_NAME
FROM @schema.@cdmTableName cdmTable
	{@cohort & '@runForCohort' == 'Yes'}?{
		JOIN @cohortDatabaseSchema.@cohortTableName c ON cdmTable.person_id = c.subject_id
			AND c.cohort_definition_id = @cohortDefinitionId
	}
	{@cdmDatatype == "datetime" | @cdmDatatype == "date"}?{
	WHERE cast(cdmTable.@cdmFieldName as date) > cast(@plausibleValueHigh as date)
}:{
	WHERE cdmTable.@cdmFieldName > @plausibleValueHigh
}
;
