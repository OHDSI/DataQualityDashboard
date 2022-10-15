
/*********
PLAUSIBLE_TEMPORAL_AFTER
get number of records and the proportion to total number of eligible records with datetimes that do not occur on or after their corresponding datetimes

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
plausibleTemporalAfterTableName = @plausibleTemporalAfterTableName
plausibleTemporalAfterFieldName = @plausibleTemporalAfterFieldName
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
		SELECT 
			'@cdmTableName.@cdmFieldName' AS violating_field, 
			cdmTable.*
    	FROM @cdmDatabaseSchema.@cdmTableName cdmTable
    		{@cdmDatabaseSchema.@cdmTableName != @cdmDatabaseSchema.@plausibleTemporalAfterTableName}?{
				JOIN @cdmDatabaseSchema.@plausibleTemporalAfterTableName plausibleTable ON cdmTable.person_id = plausibleTable.person_id}
			{@cohort & '@runForCohort' == 'Yes'}?{
    			JOIN @cohortDatabaseSchema.cohort c ON cdmTable.person_id = c.subject_id
    				AND c.cohort_definition_id = @cohortDefinitionId
			}
    WHERE 
    	{'@plausibleTemporalAfterTableName' == 'PERSON'}?{
			COALESCE(
				CAST(plausibleTable.@plausibleTemporalAfterFieldName AS DATE),
				CAST(CONCAT(plausibleTable.year_of_birth,'-06-01') AS DATE)
			) 
		}:{
			CAST(cdmTable.@plausibleTemporalAfterFieldName AS DATE)
		} > CAST(cdmTable.@cdmFieldName AS DATE)
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
) denominator
;
