
/*********
FIELD_IS_STANDARD_VALID_CONCEPT

all standard concept id fields are standard and valid

Parameters used in this template:
schema = @schema
vocabDatabaseSchema = @vocabDatabaseSchema
captureDatabaseSchema = @captureDatabaseSchema
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
	'@cdmFieldName_standard_valid' DQ_CHECK_NAME
FROM @schema.@cdmTableName cdmTable
	{@cohort & '@runForCohort' == 'Yes'}?{
		JOIN @cohortDatabaseSchema.@cohortTableName c 
		ON cdmTable.person_id = c.subject_id
		AND c.cohort_definition_id = @cohortDefinitionId
	}
	JOIN @vocabDatabaseSchema.concept co 
	ON cdmTable.@cdmFieldName = co.concept_id
WHERE co.concept_id != 0 
	AND (co.standard_concept != 'S' OR co.invalid_reason IS NOT NULL)
;
