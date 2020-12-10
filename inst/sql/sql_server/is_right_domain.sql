
/*********
CONCEPT LEVEL check:
IS RIGHT DOMAIN: checks for a given concept_id if it's reported in the right domain. 
Can only be used to check observation vs measurement. 

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
conceptId = @conceptId
wrongDomain = @wrongDomain
cdmWrongFieldName = @cdmWrongFieldName
**********/


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT COUNT_BIG(*) AS num_violated_rows
	FROM
	(
		SELECT cdmTable.* 
		FROM @cdmDatabaseSchema.@wrongDomain cdmTable
		WHERE cdmTable.@cdmWrongFieldName = @conceptId
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM 
	(
		select @cdmFieldName from @cdmDatabaseSchema.@cdmTableName
		WHERE @cdmFieldName = @conceptId 
		union ALL
		select @wrongDomain_id from @cdmDatabaseSchema.@wrongDomain
		WHERE @cdmWrongFieldName = @conceptId 
	) as results_table	
) denominator
;