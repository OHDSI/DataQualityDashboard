
/*********
FIELD_FK_DOMAIN

all standard concept ids are part of specified domain

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
captureDatabaseSchema = @captureDatabaseSchema
vocabDatabaseSchema = @vocabDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
fkDomain = @fkDomain
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
cohortTableName = @cohortTableName
}
**********/

INSERT INTO @captureDatabaseSchema.@cdmTableName
SELECT 
  cdmTable.*,
  '@cdmFieldName_fkDomain' DQ_CHECK_NAME
FROM @cdmDatabaseSchema.@cdmTableName cdmTable
  LEFT JOIN @vocabDatabaseSchema.concept co
  ON cdmTable.@cdmFieldName = co.concept_id
  {@cohort & '@runForCohort' == 'Yes'}?{
  	JOIN @cohortDatabaseSchema.@cohortTableName c 
  	ON cdmTable.person_id = c.subject_id
  	AND c.cohort_definition_id = @cohortDefinitionId
	}
WHERE co.concept_id != 0 
  AND co.domain_id NOT IN ('@fkDomain')
;
