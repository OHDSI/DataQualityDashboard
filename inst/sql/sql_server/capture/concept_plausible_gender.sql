
/*********
CONCEPT LEVEL check:
PLAUSIBLE_GENDER - number of records of a given concept which occur in person with implausible gender for that concept

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
conceptId = @conceptId
plausibleGender = @plausibleGender
{@cohort}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
cohortTableName = @cohortTableName
}
**********/

INSERT INTO @captureDatabaseSchema.@cdmTableName
SELECT 
  cdmTable.*,
  '@cdmFieldName_plausible_gender' DQ_CHECK_NAME
FROM @cdmDatabaseSchema.@cdmTableName cdmTable
	INNER JOIN @cdmDatabaseSchema.person p
	ON cdmTable.person_id = p.person_id
	{@cohort}?{
  	JOIN @cohortDatabaseSchema.@cohortTableName c
  	  ON cdmTable.person_id = c.subject_id
  	  AND c.cohort_definition_id = @cohortDefinitionId
	}
WHERE cdmTable.@cdmFieldName = @conceptId
  AND p.gender_concept_id <> {@plausibleGender == 'Male'} ? {8507} : {8532} 
;
