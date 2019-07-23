
/*********
PLAUSIBLE_VALUE_HIGH
get number of records and the proportion to total number of eligible records that exceed this threshold

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
thresholdValueHigh = @thresholdValueHigh
**********/


SELECT num_violated_rows, 1.0*num_violated_rows/denominator.num_rows AS pct_violated_rows
FROM
(
	SELECT COUNT(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.*
    from @cdmDatabaseSchema.@cdmTableName
    where @cdmFieldName > @thresholdValueHigh
	) violated_rows
) violated_row_count,
(
	SELECT COUNT(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
  where @cdmFieldName is not null
) denominator
;
