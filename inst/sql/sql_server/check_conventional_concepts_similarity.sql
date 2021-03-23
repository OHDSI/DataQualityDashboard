/*********
FIELD LEVEL check:
Follows conventions: For a given field, check if the used concept_ids are part of the conventional concepts.
Return number and % of records that are close enough to existing concepts as being wrongly mapped

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
vocabDatabaseSchema = @vocabDatabaseSchema
cdmFieldName = @cdmFieldName
similarityThresholdLevenshtein = @similarityThresholdLevenshtein
similarityThresholdJaccard = @similarityThresholdJaccard
**********/

SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT COUNT_BIG(*) AS num_violated_rows
	FROM
	(
		select * 
        from @cdmDatabaseSchema.@cdmTableName
        where @cdmFieldName in 
        (
            select distinct @cdmFieldName 
            from 
            (
                select distinct @cdmFieldName, concept_name as recorded_name
                from @cdmDatabaseSchema.@cdmTableName m
                left join @vocabDatabaseSchema.concept on m.@cdmFieldName = concept_id
                where @cdmFieldName not in 
                (
                    select concept_id_1 
                    from @vocabDatabaseSchema.concept_relationship cr
                    where cr.relationship_id = 'Is convention'
                )
            ) as unmatched_concepts, 
            (
                select distinct left(concept_synonym_name, 255) as convention_concept_name, c.concept_id as base_convention_id, c.concept_name as base_concept_name
                from @vocabDatabaseSchema.concept_relationship cr2 
                left join @vocabDatabaseSchema.concept_synonym as synonym on cr2.concept_id_1 = synonym.concept_id
                left join @vocabDatabaseSchema.concept as c on cr2.concept_id_1 = c.concept_id
                where cr2.relationship_id = 'Is convention'
            ) as convention_names
            where (levenshtein(recorded_name, convention_concept_name) < @similarityThresholdLevenshtein 
                or similarity(recorded_name, convention_concept_name) > @similarityThresholdJaccard)
                and convention_concept_name is not null
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