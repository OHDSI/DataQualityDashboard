
/*********
PLAUSIBLE_TEMPORAL_AFTER
get number of records and the proportion to total number of eligible records with datetimes that do not occur on or after their corresponding datetimes

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
plausibleTemporalAfterTableName = @plausibleTemporalAfterTableName
plausibleTemporalAfterFieldName = @plausibleTemporalAfterFieldName
**********/

SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows
FROM
(
	SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.*
    FROM @cdmDatabaseSchema.@cdmTableName
    {@cdmDatabaseSchema.@cdmTableName != @cdmDatabaseSchema.@plausibleTemporalAfterTableName}?{
		JOIN @cdmDatabaseSchema.@plausibleTemporalAfterTableName
			ON @cdmDatabaseSchema.@cdmTableName.person_id = @cdmDatabaseSchema.@plausibleTemporalAfterTableName.person_id
		}
    WHERE @plausibleTemporalAfterFieldName > @cdmFieldName
	) violated_rows
) violated_row_count,
(
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
) denominator
;
