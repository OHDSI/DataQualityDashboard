/*********
Field Level:  
IS WITHIN OBSERVATION PERIOD
Determine what #/% of records are not within one of the observation periods for that patient.

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
idField = @idField
**********/

SELECT
	num_violated_rows,
	CASE
		WHEN denominator.num_rows = 0 THEN 0
		ELSE 1.0 * num_violated_rows / denominator.num_rows
	END AS pct_violated_rows,
	denominator.num_rows AS num_denominator_rows
FROM
	(
	SELECT
		count(DISTINCT @idField) AS num_violated_rows
	FROM
		(
		SELECT
			DISTINCT @idField, count(CASE WHEN is_between THEN 1 END)
		FROM
			(
			SELECT
				m.@idField, op.observation_period_id, m.@cdmFieldName BETWEEN op.observation_period_start_date AND op.observation_period_end_date AS is_between
			FROM
				@cdmDatabaseSchema.@cdmTableName m
			LEFT JOIN @cdmDatabaseSchema.observation_period op ON
				m.person_id = op.person_id) check_between
		GROUP BY
			@idField ) violated_rows WHERE count = 0 ) violated_row_count,
	(
	SELECT
		COUNT(*) AS num_rows
	FROM 
	(
		SELECT * FROM @cdmDatabaseSchema.@cdmTableName m3 
	) as results_table
) denominator
;

