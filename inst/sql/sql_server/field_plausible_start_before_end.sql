
/*********
PLAUSIBLE_START_BEFORE_END
Checks that all start dates are before their corresponding end dates (PLAUSIBLE_START_BEFORE_END == Yes).
@cdmFieldName is the start date and @plausibleStartBeforeEndFieldName is the end date.

Parameters used in this template:
schema = @schema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
plausibleStartBeforeEndFieldName = @plausibleStartBeforeEndFieldName
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
            cdmTable.*
        FROM @schema.@cdmTableName cdmTable
        {@cohort & '@runForCohort' == 'Yes'} ? {
        JOIN @cohortDatabaseSchema.@cohortTableName c 
            ON cdmTable.person_id = c.subject_id
            AND c.cohort_definition_id = @cohortDefinitionId
        }
        WHERE cdmTable.@cdmFieldName IS NOT NULL 
            AND cdmTable.@plausibleStartBeforeEndFieldName IS NOT NULL 
            AND CAST(cdmTable.@cdmFieldName AS DATE) > CAST(cdmTable.@plausibleStartBeforeEndFieldName AS DATE)
        /*violatedRowsEnd*/
    ) violated_rows
) violated_row_count,
(
    SELECT 
        COUNT_BIG(*) AS num_rows
    FROM @schema.@cdmTableName cdmTable
    {@cohort & '@runForCohort' == 'Yes'} ? {
    JOIN @cohortDatabaseSchema.@cohortTableName c 
        ON cdmTable.person_id = c.subject_id
        AND c.cohort_definition_id = @cohortDefinitionId 
    }
    WHERE cdmTable.@cdmFieldName IS NOT NULL 
        AND cdmTable.@plausibleStartBeforeEndFieldName IS NOT NULL
) denominator
;
