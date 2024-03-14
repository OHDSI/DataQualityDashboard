/*********
CONCEPT LEVEL check:
ICU_CONCEPT_IDS_OF_INTEREST - find proportion of records with concept_ids of interest
Note that concepts outside of the interest list are not true failures (they are still data!)
, they simply don't fall under our concept search

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
contextModuleTableName = @contextModuleTableName
contextModuleFieldName = @contextModuleFieldName
contextModuleConceptIds = @contextModuleConceptIds
{@cohort & '@runForCohort' == 'Yes'} ? {
        JOIN @cohortDatabaseSchema.@cohortTableName c
            ON cdmTable.person_id = c.subject_id
            AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
}
**********/


SELECT
  denominator.num_rows - num_rows_of_interest AS num_violated_rows,
	CASE
		WHEN denominator.num_rows = 0 THEN 0
		ELSE 1.0*(denominator.num_rows - num_rows_of_interest)/denominator.num_rows
	END AS pct_violated_rows,
	denominator.num_rows AS num_denominator_rows
FROM
(
	SELECT
	  COUNT_BIG(*) AS num_rows_of_interest
	FROM
	(
		SELECT
		  cdmTable.*
		FROM @cdmDatabaseSchema.@contextModuleTableName cdmTable
  		{@cohort & '@runForCohort' == 'Yes'} ? {
        JOIN @cohortDatabaseSchema.@cohortTableName c
            ON cdmTable.person_id = c.subject_id
            AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
        }
        JOIN @cdmDatabaseSchema.@cdmTableName v
            ON cdmTable.person_id = v.person_id
            AND cdmTable.visit_occurrence_id = v.visit_occurrence_id
		WHERE cdmTable.@contextModuleFieldName IN (@contextModuleConceptIds)
		  	AND v.@cdmFieldName IN (@conceptId)
	) rows_of_interest
) violated_row_count,
(
	SELECT
	  COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@contextModuleTableName cdmTable
  	{@cohort & '@runForCohort' == 'Yes'} ? {
        JOIN @cohortDatabaseSchema.@cohortTableName c
            ON cdmTable.person_id = c.subject_id
            AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
    }
	JOIN @cdmDatabaseSchema.@cdmTableName v
            ON cdmTable.person_id = v.person_id
            AND cdmTable.visit_occurrence_id = v.visit_occurrence_id
		WHERE v.@cdmFieldName IN (@conceptId)
) denominator
;
