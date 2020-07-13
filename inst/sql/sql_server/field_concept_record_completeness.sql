/*********
CONCEPT_RECORD_COMPLETENESS
number of 0s / total number of records {@cdmTableName in ('OBSERVATION', 'MEASUREMENT')}{*for the OBSERVATION.unit_concept and MEASUREMENT.concept_id 
the numerator and denominator are limited to records where value_as_number IS NOT NULL}

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
**********/

SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, cdmTable.* 
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		WHERE cdmTable.@cdmFieldName = 0 {@cdmTableName in ('OBSERVATION', 'MEASUREMENT')}?{AND cdmTable.value_as_number IS NOT NULL}
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName cdmTable {@cdmTableName in ('OBSERVATION', 'MEASUREMENT')}?{WHERE cdmTable.value_as_number IS NOT NULL}
) denominator
;
