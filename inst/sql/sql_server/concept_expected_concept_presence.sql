/*********
CONCEPT LEVEL check:
EXPECTED_CONCEPT_PRESENCE - find records whose @cdmFieldName is not the expected CONCEPT_ID.
The check fails when the share of records without the expected concept exceeds the threshold,
i.e. when the expected concept is under-represented (e.g. a status flag dropped during ETL).

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
conceptId = @conceptId
{@cohort}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
cohortTableName = @cohortTableName
}
**********/


SELECT
  num_violated_rows,
	CASE
		WHEN denominator.num_rows = 0 THEN 0
		ELSE 1.0*num_violated_rows/denominator.num_rows
	END AS pct_violated_rows,
	denominator.num_rows AS num_denominator_rows
FROM
(
	SELECT
	  COUNT_BIG(*) AS num_violated_rows
	FROM
	(
		/*violatedRowsBegin*/
		SELECT
		  cdmTable.*
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
  		{@cohort}?{
        JOIN @cohortDatabaseSchema.@cohortTableName c
    		ON cdmTable.person_id = c.subject_id
    		AND c.cohort_definition_id = @cohortDefinitionId
    	}
		WHERE cdmTable.@cdmFieldName IS NULL
			OR cdmTable.@cdmFieldName != @conceptId
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
(
	SELECT
	  COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
  	{@cohort}?{
    	JOIN @cohortDatabaseSchema.@cohortTableName c
    		ON cdmTable.person_id = c.subject_id
    		AND c.cohort_definition_id = @cohortDefinitionId
  	}
) denominator
;
