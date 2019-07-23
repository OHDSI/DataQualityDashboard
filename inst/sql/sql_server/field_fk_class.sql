
/*********
FK_CLASS
Drug era standard concepts, ingredients only

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
fkDomain = @fkDomain
fkClass = @fkClass
**********/


SELECT num_violated_rows, 1.0*num_violated_rows/denominator.num_rows AS pct_violated_rows
FROM
(
	SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.* 
		FROM @cdmDatabaseSchema.@cdmTableName
		LEFT JOIN @cdmDatabaseSchema.CONCEPT 
		ON @cdmTableName.@cdmFieldName = CONCEPT.CONCEPT_ID
        WHERE CONCEPT.DOMAIN_ID != '@fkDomain' OR CONCEPT.CONCEPT_CLASS_ID != '@fkClass' 
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;
