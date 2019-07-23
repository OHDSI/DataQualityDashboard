
/*********
CONCEPT LEVEL check:
PLAUSIBLE_VALUE_LOW - find any MEASUREMENT records that have VALUE_AS_NUMBER with non-null value < plausible low value

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
conceptId = @conceptId
unitConceptId = @unitConceptId
plausibleValueLow = @plausibleValueLow

**********/


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows
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
		AND value_as_number < @plausibleValueLow
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