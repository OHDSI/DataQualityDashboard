
/*********
FIELD_IS_NOT_NULLABLE

For each table, check that the fields in which IS_NOT_NULLABLE == TRUE, there are no null values in that field.

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
cdmFieldName = @cdmFieldName
{@cohort & '@runForCohort' == 'Yes'}?{
cohortDefinitionId = @cohortDefinitionId
cohortDatabaseSchema = @cohortDatabaseSchema
}
**********/

{@CLEANSE} ? {
	INSERT INTO @cdmDatabaseSchema.@cdmTableName_archive
		SELECT cdmTable.* 
		  FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		 WHERE cdmTable.@cdmFieldName IS NULL; 
	
	DELETE FROM @cdmDatabaseSchema.@cdmTableName WHERE @cdmFieldName IS NULL;
}

{@EXECUTE} ? {
	SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END  AS pct_violated_rows, 
	  denominator.num_rows as num_denominator_rows
	FROM
	(
		SELECT COUNT_BIG(violated_rows.violating_field) AS num_violated_rows
		FROM
		(
			SELECT '@cdmTableName.@cdmFieldName' AS violating_field, cdmTable.* 
			  FROM @cdmDatabaseSchema.@cdmTableName cdmTable
			  {@cohort & '@runForCohort' == 'Yes'}?{
			JOIN @cohortDatabaseSchema.COHORT c 
			ON cdmTable.PERSON_ID = c.SUBJECT_ID
			AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
			}
			 WHERE cdmTable.@cdmFieldName IS NULL
		) violated_rows
	) violated_row_count,
	( 
		SELECT COUNT_BIG(*) AS num_rows
		FROM @cdmDatabaseSchema.@cdmTableName cdmTable
		{@cohort & '@runForCohort' == 'Yes'}?{
			JOIN @cohortDatabaseSchema.COHORT c 
			ON cdmTable.PERSON_ID = c.SUBJECT_ID
			AND c.COHORT_DEFINITION_ID = @cohortDefinitionId
			}
	) denominator;
}
