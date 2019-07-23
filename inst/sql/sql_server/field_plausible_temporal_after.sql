
/*********
PLAUSIBLE_TEMPORAL_AFTER
get number of records and the proportion to total number of eligible records with datetimes that do not occur on or after their corresponding datetimes

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
temoralComparatorTableName = @temoralComparatorTableName
temporalComparatorFieldName = @temporalComparatorFieldName
**********/


SELECT num_violated_rows, 1.0*num_violated_rows/denominator.num_rows AS pct_violated_rows
FROM
(
	SELECT COUNT(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.*
    from @cdmDatabaseSchema.@cdmTableName
		join @cdmDatabaseSchema.@temoralComparatorTableName
			on @cdmDatabaseSchema.@cdmTableName.person_id = @cdmDatabaseSchema.@temoralComparatorTableName.person_id
    where @temporalComparatorFieldName > @cdmFieldName
	) violated_rows
) violated_row_count,
(
	SELECT COUNT(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;
