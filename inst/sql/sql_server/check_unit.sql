
/*********
CONCEPT LEVEL check:
IS RIGHT DOMAIN: checks for a given concept_id if it's reported in the right domain. 
Can only be used to check observation vs measurement. 

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
vocabDatabaseSchema = @vocabDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
conceptId = @conceptId
cdmValueFieldName = @cdmValueFieldName
**********/


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT COUNT_BIG(*) AS num_violated_rows
	FROM
	(
		SELECT cdmTable.* 
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		WHERE cdmTable.@cdmFieldName = @conceptId
        and @cdmValueFieldName not in 
        (
            select concept_id_2 
            from @vocabDatabaseSchema.concept_relationship relation
            WHERE relation.concept_id_1 = @conceptId
            and relation.relationship_id = 'Has unit'
        )
        and @cdmValueFieldName is not null
        and exists 
        (
            select * from @cdmDatabaseSchema.@cdmTableName
            where @cdmFieldName = @conceptId
        )
        and exists 
        (
            select *
            from @vocabDatabaseSchema.concept_relationship relation
            WHERE relation.concept_id_1 = @conceptId
            and relation.relationship_id = 'Has unit'
        )
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM 
	(
		SELECT cdmTable.* 
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		WHERE cdmTable.@cdmFieldName = @conceptId
        and exists 
        (
            select *
            from @vocabDatabaseSchema.concept_relationship relation
            WHERE relation.concept_id_1 = @conceptId
            and relation.relationship_id = 'Has unit'
        )
	) as results_table	
) denominator
;