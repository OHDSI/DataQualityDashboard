/*********
PLAUSIBLE_AFTER_BIRTH
Checks that all events happen after birth (PLAUSIBLE_AFTER_BIRTH == Yes)
Birthdate is either birth_datetime or composed from year_of_birth, month_of_birth, day_of_birth (taking 1st month/1st day if missing).
Denominator is number of events with a non-null date.

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
            cdmTable.*
        FROM @cdmDatabaseSchema.@cdmTableName cdmTable
        {@cohort & '@runForCohort' == 'Yes'} ? {
        JOIN @cohortDatabaseSchema.@cohortTableName c 
            ON cdmTable.person_id = c.subject_id
            AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
        }
        JOIN @cdmDatabaseSchema.person p 
            ON cdmTable.person_id = p.person_id
        WHERE cdmTable.@cdmFieldName IS NOT NULL AND 
            CAST(cdmTable.@cdmFieldName AS DATE) < COALESCE(
                CAST(p.birth_datetime AS DATE), 
                CAST(CONCAT(
                    p.year_of_birth,
                    COALESCE(
                        RIGHT('0' + CAST(p.month_of_birth AS VARCHAR), 2),
                        '01'
                    ),
                    COALESCE(
                        RIGHT('0' + CAST(p.day_of_birth AS VARCHAR), 2),
                        '01'
                    )
                ) AS DATE)
            )
        /*violatedRowsEnd*/
    ) violated_rows
) violated_row_count,
(
    SELECT 
        COUNT_BIG(*) AS num_rows
    FROM @cdmDatabaseSchema.@cdmTableName cdmTable
    {@cohort & '@runForCohort' == 'Yes'} ? {
    JOIN @cohortDatabaseSchema.@cohortTableName c 
        ON cdmTable.person_id = c.subject_id
        AND c.cohort_definition_id = @cohortDefinitionId
    }
    WHERE cdmTable.@cdmFieldName IS NOT NULL
) denominator
;
