/*
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName
cdmFieldName
*/
SELECT
violations,
total_count
FROM (
    SELECT COUNT_BIG(*) AS violations
    FROM @cdmDatabaseSchema.@cdmTableName AS cdmTable
    INNER JOIN @cdmDatabaseSchema.visit_occurrence AS vo
    ON cdmTable.visit_occurrence_id = vo.visit_occurrence_id
    AND (
        cdmTable.@cdmFieldName < vo.visit_start_date
        OR cdmTable.@cdmFieldName > vo.visit_end_date
    )
) AS violators
INNER JOIN (
    SELECT COUNT_BIG(*) AS total_count 
    FROM @cdmDatabaseSchema.@cdmTableName AS cdmTable
    INNER JOIN @cdmDatabaseSchema.visit_occurrence AS vo
    ON cdmTable.visit_occurrence_id = vo.visit_occurrence_id
) AS total