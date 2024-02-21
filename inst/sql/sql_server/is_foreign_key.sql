
/*********
IS_FOREIGN_KEY

Foreign key check.

Parameters used in this template:
schema = @schema
{'@fkTableName' IN ('CONCEPT','DOMAIN','CONCEPT_CLASS','VOCABULARY','RELATIONSHIP')}?{vocabDatabaseSchema = @vocabDatabaseSchema}
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
fkTableName = @fkTableName
fkFieldName = @fkFieldName
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
cohortTableName = @cohortTableName
}
**********/


SELECT num_violated_rows,
    CASE
        WHEN denominator.num_rows = 0 THEN 0 
        ELSE 1.0*num_violated_rows/denominator.num_rows
    END AS pct_violated_rows,
    denominator.num_rows AS num_denominator_rows
FROM (
    SELECT 
        COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
    FROM (
        /*violatedRowsBegin*/
        SELECT 
            '@cdmTableName.@cdmFieldName' AS violating_field, 
            cdmTable.*
        FROM @schema.@cdmTableName cdmTable
            {@cohort & '@runForCohort' == 'Yes'}?{
                JOIN @cohortDatabaseSchema.@cohortTableName c
                    ON cdmTable.person_id = c.subject_id
                    AND c.cohort_definition_id = @cohortDefinitionId
            }
            LEFT JOIN 
                {'@fkTableName' IN ('CONCEPT','DOMAIN','CONCEPT_CLASS','VOCABULARY','RELATIONSHIP')}?{@vocabDatabaseSchema.@fkTableName fkTable}
                {'@fkTableName' == 'COHORT'}?{@cohortDatabaseSchema.@fkTableName fkTable}
                {'@fkTableName' IN ('LOCATION','PERSON','PROVIDER','VISIT_DETAIL','VISIT_OCCURRENCE','PAYER_PLAN_PERIOD','NOTE','CARE_SITE','EPISODE')}?{@cdmDatabaseSchema.@fkTableName fkTable} 
                ON cdmTable.@cdmFieldName = fkTable.@fkFieldName
        WHERE fkTable.@fkFieldName IS NULL 
            AND cdmTable.@cdmFieldName IS NOT NULL
        /*violatedRowsEnd*/
    ) violated_rows
) violated_row_count,
(
    SELECT 
        COUNT_BIG(*) AS num_rows
    FROM @schema.@cdmTableName cdmTable
        {@cohort & '@runForCohort' == 'Yes'}?{
            JOIN @cohortDatabaseSchema.@cohortTableName c
                ON cdmTable.person_id = c.subject_id
                AND c.cohort_definition_id = @cohortDefinitionId
        }
) denominator
;
