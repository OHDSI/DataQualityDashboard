
/*********
FK_CLASS
Drug era standard concepts, ingredients only

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
vocabDatabaseSchema = @vocabDatabaseSchema
captureDatabaseSchema = @captureDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
fkClass = @fkClass
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
cohortTableName = @cohortTableName
}
**********/

INSERT INTO @captureDatabaseSchema.@cdmTableName
SELECT 
  cdmTable.*,
  '@cdmFieldName_fkClass' DQ_CHECK_NAME
FROM @cdmDatabaseSchema.@cdmTableName cdmTable
  LEFT JOIN @vocabDatabaseSchema.concept co
  ON cdmTable.@cdmFieldName = co.concept_id
  {@cohort & '@runForCohort' == 'Yes'}?{
  	JOIN @cohortDatabaseSchema.@cohortTableName c 
  	ON cdmTable.person_id = c.subject_id
  	AND c.cohort_definition_id = @cohortDefinitionId
	}
WHERE co.concept_id != 0 
  AND (co.concept_class_id != '@fkClass') 
;
