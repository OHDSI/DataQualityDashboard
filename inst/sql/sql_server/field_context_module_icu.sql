/*********
PLAUSIBLE_ICU_VISIT
Checks that all events associated with a visit happen WITHIN that visit temporally
This check will also conveniently fail if (start) datetime fields are not filled or potentially
if they are autofilled (date + 00:00:00) for inpatient visits.
Denominator is number of events with an out-of-range date.

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
        COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
    FROM
    (
        /*violatedRowsBegin*/
        SELECT
            '@cdmTableName.@cdmFieldName' AS violating_field,
            cdmTable.@cdmFieldName
        FROM @cdmDatabaseSchema.@cdmTableName cdmTable
        {@cohort & '@runForCohort' == 'Yes'} ? {
        JOIN @cohortDatabaseSchema.@cohortTableName c
            ON cdmTable.person_id = c.subject_id
            AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
        }
        JOIN @cdmDatabaseSchema.visit_occurrence v
            ON cdmTable.person_id = v.person_id
            AND cdmTable.visit_occurrence_id = v.visit_occurrence_id
        WHERE (cdmTable.@cdmFieldName IS NULL
            OR (cdmTable.@cdmFieldName < v.visit_start_datetime
                OR cdmTable.@cdmFieldName > v.visit_end_datetime))
            AND v.visit_concept_id IN (262, 9201, 8717, 32037, 581383, 581379)
    ) violated_rows
        /*violatedRowsEnd*/
) violated_rows_count,
(
    SELECT
        COUNT_BIG(*) AS num_rows
    FROM @cdmDatabaseSchema.@cdmTableName cdmTable
        {@cohort & '@runForCohort' == 'Yes'} ? {
        JOIN @cohortDatabaseSchema.@cohortTableName c
            ON cdmTable.person_id = c.subject_id
            AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
        }
        JOIN @cdmDatabaseSchema.visit_occurrence v
            ON cdmTable.person_id = v.person_id
            AND cdmTable.visit_occurrence_id = v.visit_occurrence_id
        WHERE v.visit_concept_id IN (262, 9201, 8717, 32037, 581383, 581379)
) denominator
;
