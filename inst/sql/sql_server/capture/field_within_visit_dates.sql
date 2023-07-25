/*********
FIELD LEVEL check:
WITHIN_VISIT_DATES - find events that occur one week before the corresponding visit_start_date or one week after the corresponding visit_end_date

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
  '@cdmFieldName_within_visit_dates' DQ_CHECK_NAME
FROM @cdmDatabaseSchema.@cdmTableName cdmTable
  {@cohort & '@runForCohort' == 'Yes'}?{
    JOIN @cohortDatabaseSchema.@cohortTableName c
    ON cdmTable.person_id = c.subject_id
    AND c.cohort_definition_id = @cohortDefinitionId
  }
  JOIN @cdmDatabaseSchema.visit_occurrence vo
  ON cdmTable.visit_occurrence_id = vo.visit_occurrence_id
WHERE cdmTable.@cdmFieldName < dateadd(day, -7, vo.visit_start_date)
  OR cdmTable.@cdmFieldName > dateadd(day, 7, vo.visit_end_date)
;