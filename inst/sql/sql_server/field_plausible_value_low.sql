
/*********
PLAUSIBLE_VALUE_LOW
get number of records and the proportion to total number of eligible records that fall below this threshold

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
plausibleValueLow = @plausibleValueLow
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
}
**********/

SELECT num_violated_rows,
  CASE
    WHEN denominator.num_rows = 0 THEN 0 
    ELSE 1.0*num_violated_rows/denominator.num_rows
  END AS pct_violated_rows,
  denominator.num_rows AS num_denominator_rows
FROM (
	SELECT 
	  COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM (
		/*violatedRowsBegin*/
		SELECT 
		  '@cdmTableName.@cdmFieldName' AS violating_field, 
		  cdmTable.*
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
  		{@cohort & '@runForCohort' == 'Yes'}?{
        JOIN @cohortDatabaseSchema.cohort c
        ON cdmTable.person_id = c.subject_id
        AND c.cohort_definition_id = @cohortDefinitionId
      }
    {@cdmDatatype == "datetime" | @cdmDatatype == "date"}?{
    WHERE CAST(cdmTable.@cdmFieldName AS DATE) < CAST(@plausibleValueLow AS DATE)
    }:{
    WHERE cdmTable.@cdmFieldName < @plausibleValueLow
    }
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
(
	SELECT 
	  COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
	  {@cohort & '@runForCohort' == 'Yes'}?{
      JOIN @cohortDatabaseSchema.cohort c
      ON cdmTable.person_id = c.subject_id
      AND c.cohort_definition_id = @cohortDefinitionId
    }
	WHERE @cdmFieldName IS NOT NULL
) denominator
;
