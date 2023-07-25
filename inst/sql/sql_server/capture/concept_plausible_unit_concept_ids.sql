/*********
CONCEPT LEVEL check:
PLAUSIBLE_UNIT_CONCEPT_IDS - find any MEASUREMENT records that are associated with an incorrect UNIT_CONCEPT_ID

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
conceptId = @conceptId
plausibleUnitConceptIds = @plausibleUnitConceptIds
{@cohort}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
cohortTableName = @cohortTableName
}
**********/

INSERT INTO @captureDatabaseSchema.@cdmTableName
SELECT 
  cdmTable.*,
  '@conceptId_plausible_unit_concept_ids' DQ_CHECK_NAME
FROM @cdmDatabaseSchema.@cdmTableName m
	{@cohort}?{
    JOIN @cohortDatabaseSchema.@cohortTableName c
		ON m.person_id = c.subject_id
		AND c.cohort_definition_id = @cohortDefinitionId
	}
WHERE m.@cdmFieldName = @conceptId
  AND {@plausibleUnitConceptIds == '' | @plausibleUnitConceptIds == 'NA'}?{
  m.unit_concept_id IS NOT NULL
  }:{
  m.unit_concept_id NOT IN (@plausibleUnitConceptIds)
  }
  AND m.value_as_number IS NOT NULL 
  AND (m.unit_source_value IS NOT NULL OR m.unit_source_value <> '')
;
