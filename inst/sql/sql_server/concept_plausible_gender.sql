
/*********
CONCEPT LEVEL check:
PLAUSIBLE_GENDER - number of records of a given concept which occur in person with implausible gender for that concept

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
conceptId = @conceptId
plausibleGender = @plausibleGender

**********/


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END AS pct_violated_rows
FROM
(
	SELECT COUNT_BIG(*) AS num_violated_rows
	FROM
	(
		SELECT @cdmTableName.* 
		FROM @cdmDatabaseSchema.@cdmTableName
			INNER JOIN @cdmDatabaseSchema.person
			ON @cdmTableName.person_id = person.person_id
		WHERE @cdmFieldName = @conceptId
		AND person.gender_concept_id <> {@plausibleGender == 'Male'} ? {8507} : {8532} 
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
	WHERE @cdmFieldName = @conceptId
) denominator
;