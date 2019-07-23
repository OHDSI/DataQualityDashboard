
/*********
CONCEPT LEVEL check:
PLAUSIBLE_VALUE_HIGH - find any MEASUREMENT records that have VALUE_AS_NUMBER with non-null value > plausible high value

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
conceptId = @conceptId
unitConceptId = @unitConceptId
plausibleValueHigh = @plausibleValueHigh

**********/


SELECT num_violated_rows, 1.0*num_violated_rows/denominator.num_rows AS pct_violated_rows
FROM
(
	SELECT COUNT(*) AS num_violated_rows
	FROM
	(
		SELECT measurement.* 
		FROM @cdmDatabaseSchema.measurement
		WHERE measurement_concept_id = @conceptId
		AND unit_concept_id = @unitConceptId
		AND value_as_number IS NOT NULL
		AND value_as_number > @plausibleValueHigh
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT(*) AS num_rows
	FROM @cdmDatabaseSchema.measurement
	WHERE measurement_concept_id = @conceptId
	AND unit_concept_id = @unitConceptId
	AND value_as_number IS NOT NULL
) denominator
;