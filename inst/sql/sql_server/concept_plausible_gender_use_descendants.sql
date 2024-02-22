/*********
CONCEPT LEVEL check:
PLAUSIBLE_GENDER_USE_DESCENDANTS - number of records of descendants of a given concept which occur in person with implausible gender for that concept set

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
vocabDatabaseSchema = @vocabDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
conceptId = @conceptId
plausibleGenderUseDescendants = @plausibleGenderUseDescendants
{@cohort}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
cohortTableName = @cohortTableName
}
**********/


SELECT 
	num_violated_rows, 
	CASE 
		WHEN denominator.num_rows = 0 THEN 0 
		ELSE 1.0*num_violated_rows/denominator.num_rows 
	END AS pct_violated_rows, 
	denominator.num_rows AS num_denominator_rows
FROM
(
	SELECT 
		COUNT_BIG(*) AS num_violated_rows
	FROM
	(
		/*violatedRowsBegin*/
		SELECT cdmTable.* 
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
			JOIN @cdmDatabaseSchema.person p
				ON cdmTable.person_id = p.person_id
			JOIN @vocabDatabaseSchema.concept_ancestor ca
				ON ca.descendant_concept_id = cdmTable.@cdmFieldName
			{@cohort}?{
			JOIN @cohortDatabaseSchema.@cohortTableName c
				ON cdmTable.person_id = c.subject_id
				AND c.cohort_definition_id = @cohortDefinitionId
			}
		WHERE ca.ancestor_concept_id IN (@conceptId)
		AND p.gender_concept_id <> {@plausibleGenderUseDescendants == 'Male'} ? {8507} : {8532} 
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
( 
	SELECT 
		COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		JOIN @vocabDatabaseSchema.concept_ancestor ca
			ON ca.descendant_concept_id = cdmTable.@cdmFieldName
		{@cohort}?{
		JOIN @cohortDatabaseSchema.@cohortTableName c
			ON cdmTable.person_id = c.subject_id
			AND c.cohort_definition_id = @cohortDefinitionId
		}
	WHERE ca.ancestor_concept_id IN (@conceptId)
) denominator
;
