/*********
FIELD LEVEL check:
Follows conventions: For a given field, check if the used concept_ids are part of the conventional concepts.
Return number and % of records that are close enough to existing concepts as being wrongly mapped

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
vocabDatabaseSchema = @vocabDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
**********/

SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT COUNT_BIG(*) AS num_violated_rows
	FROM
	(
        select *
        from @cdmDatabaseSchema.@cdmTableName m
        where @cdmFieldName not in 
        (
            select concept_id_1 
            from @vocabDatabaseSchema.concept_relationship
			join @vocabDatabaseSchema.concept
			on concept_id_1 = concept_id
            where relationship_id = 'Is convention' and @vocabDatabaseSchema.concept.standard_concept = 'S' and @vocabDatabaseSchema.concept.invalid_reason is null
        )
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM 
	(
		SELECT cdmTable.* 
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
	) as results_table	
) denominator
;