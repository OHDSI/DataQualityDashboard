/*********
SQL to create query for insertion into results table. These may be unioned together prior to insert.
Note that this does not include information about SQL errors or performance.
**********/

SELECT 
  cte.num_violated_rows
  ,cte.pct_violated_rows
  ,cte.num_denominator_rows
  ,'' as execution_time
  ,'' as query_text
  ,'@checkName' as check_name
  ,'@checkLevel' as check_level
  ,'@renderedCheckDescription' as check_description
  ,'@cdmTableName' as cdm_table_name
  ,'@cdmFieldName' as cdm_field_name
  ,'@conceptId' as concept_id
  ,'@unitConceptId' as unit_concept_id
  ,'@sqlFile' as sql_file
  ,'@category' as category
  ,'@subcategory' as subcategory
  ,'@context' as context
  ,'' as warning
  ,'' as error
  ,'@checkId' as checkid
  ,0 as is_error
  ,0 as not_applicable
  ,CASE WHEN (cte.pct_violated_rows * 100) > @thresholdValue THEN 1 ELSE 0 END as failed
  ,CASE WHEN (cte.pct_violated_rows * 100) <= @thresholdValue THEN 1 ELSE 0 END as passed
  ,NULL as not_applicable_reason
  ,@thresholdValue as threshold_value
  ,NULL as notes_value
FROM (
  @queryText
) cte
