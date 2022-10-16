
/*********
PLAUSIBLE_VALUE_HIGH
get number of records and the proportion to total number of eligible records that exceed this threshold

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
plausibleValueHigh = @plausibleValueHigh
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
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
		COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		/*violatedRowsBegin*/
		SELECT '@cdmTableName.@cdmFieldName' AS violating_field, 
		cdmTable.*
    	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
    		{@cohort & '@runForCohort' == 'Yes'}?{
    			JOIN @cohortDatabaseSchema.cohort c ON cdmTable.person_id = c.subject_id
    				AND c.cohort_definition_id = @cohortDefinitionId
    		}
    		{@cdmDatatype == "datetime" | @cdmDatatype == "date"}?{
      	WHERE cast(cdmTable.@cdmFieldName as date) > cast(@plausibleValueHigh as date)
    	}:{
      		WHERE cdmTable.@cdmFieldName > @plausibleValueHigh
		}
		/*violatedRowsEnd*/
	) violated_rows
) violated_row_count,
(
	SELECT 
		COUNT_BIG(*) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		{@cohort & '@runForCohort' == 'Yes'}?{
    		JOIN @cohortDatabaseSchema.cohort c ON cdmTable.person_id = c.subject_id
    			AND c.cohort_definition_id = @cohortDefinitionId
    	}
  	WHERE @cdmFieldName IS NOT NULL
) denominator
;
