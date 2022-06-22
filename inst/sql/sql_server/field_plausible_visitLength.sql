/*********
FIELD LEVEL CHECK:
Check visit in patient visit dates are more than one day, ER visits are less than 2 days

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
}
**********/
SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT COUNT(*) AS num_violated_rows
	FROM
	(
		SELECT  cdmTable.*
	FROM cdm_synthea_v1.visit_occurrence cdmTable
    WHERE  (cdmTable.visit_concept_id =9203 AND
          (DAY(cdmTable.visit_end_date) - DAY(cdmTable.visit_start_date)) <2)
          OR  (cdmTable.visit_concept_id = 9201 AND
           (DAY(cdmTable.visit_end_date) - DAY(cdmTable.visit_start_date)) <1)
	) violated_rows
) violated_row_count,
(
	SELECT COUNT(*) AS num_rows
	FROM cdm_synthea_v1.visit_occurrence cdmTable
   ) denominator
;
SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT COUNT(*) AS num_violated_rows
	FROM
	(
		SELECT  cdmTable.*
	FROM @CdmDatabaseSchema.@cdmTableName cdmTable
        {@cohort & '@runForCohort' == 'Yes'}?{
         JOIN @cohortDatabaseSchema.cohort c
          on cdmTable.PERSON_ID =c.SUBJECT_ID
         AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
        }
    WHERE  (cdmTable.visit_concept_id =9203 AND
          (DAY(cdmTable.visit_end_date) - DAY(cdmTable.visit_start_date)) <2)
          OR  (cdmTable.visit_concept_id = 9201 AND
           (DAY(cdmTable.visit_end_date) - DAY(cdmTable.visit_start_date)) <1)
	) violated_rows
) violated_row_count,
(
	SELECT COUNT(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
	{@cohort & '@runForCohort' == 'Yes'}?{
  JOIN @cohortDatabaseSchema.COHORT c 
    ON cdmTable.PERSON_ID = c.SUBJECT_ID
    AND c.COHORT_DEFINITION_ID = @cohortDefinitionId }
   ) denominator
;

            
