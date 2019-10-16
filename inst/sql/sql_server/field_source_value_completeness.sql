/*********
SOURCE_VALUE_COMPLETENESS
number of source values with 0 standard concept / number of distinct source values

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
standardConceptFieldName = @standardConceptFieldName
**********/

SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows
FROM
(
	SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
	FROM
	(
		SELECT DISTINCT '@cdmTableName.@cdmFieldName' AS violating_field, @cdmTableName.@cdmFieldName
		FROM @cdmDatabaseSchema.@cdmTableName
		{@cohort & '@runForCohort' == 'Yes'}?{
    	JOIN @cohortDatabaseSchema.COHORT 
    	ON @cdmTableName.PERSON_ID = COHORT.SUBJECT_ID
    	AND COHORT.COHORT_DEFINITION_ID = @cohortDefinitionId
    	}
		WHERE @cdmDatabaseSchema.@cdmTableName.@standardConceptFieldName = 0
	) violated_rows
) violated_row_count,
( 
	SELECT COUNT_BIG(distinct @cdmTableName.@cdmFieldName) AS num_rows
	FROM @cdmDatabaseSchema.@cdmTableName
	{@cohort & '@runForCohort' == 'Yes'}?{
  	JOIN @cohortDatabaseSchema.COHORT 
  	ON @cdmTableName.PERSON_ID = COHORT.SUBJECT_ID
  	AND COHORT.COHORT_DEFINITION_ID = @cohortDefinitionId
  	}
) denominator
;
