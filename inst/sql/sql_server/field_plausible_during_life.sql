
/*********
PLAUSIBLE_DURING_LIFE
get number of events that occur after death event (PLAUSIBLE_DURING_LIFE == Yes)

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
**********/


SELECT num_violated_rows, 1.0*num_violated_rows/denominator.num_rows AS pct_violated_rows
FROM
(
	SELECT COUNT(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.*
    from @cdmDatabaseSchema.@cdmTableName
    join @cdmDatabaseSchema.death on @cdmDatabaseSchema.@cdmTableName.person_id = @cdmDatabaseSchema.death.person_id
    where @cdmFieldName > death_date
	) violated_rows
) violated_row_count,
(
	SELECT COUNT(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
	where person_id in
	( select person_id from @cdmDatabaseSchema.death )
) denominator
;
