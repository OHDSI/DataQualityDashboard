
/*********
PLAUSIBLE_VALUE_LOW
get number of records and the proportion to total number of eligible records that fall below this threshold

Parameters used in this template:
schema = @schema
captureDatabaseSchema = @captureDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
plausibleValueLow = @plausibleValueLow
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
cohortTableName = @cohortTableName
}
**********/

INSERT INTO @captureDatabaseSchema.@cdmTableName
SELECT 
  cdmTable.*,
  '@cdmFieldName_plausible_value_low' DQ_CHECK_NAME
FROM @schema.@cdmTableName cdmTable
	{@cohort & '@runForCohort' == 'Yes'}?{
    JOIN @cohortDatabaseSchema.@cohortTableName c
    ON cdmTable.person_id = c.subject_id
    AND c.cohort_definition_id = @cohortDefinitionId
  }
{@cdmDatatype == "datetime" | @cdmDatatype == "date"}?{
WHERE CAST(cdmTable.@cdmFieldName AS DATE) < CAST(@plausibleValueLow AS DATE)
}:{
WHERE cdmTable.@cdmFieldName < @plausibleValueLow
}
;
