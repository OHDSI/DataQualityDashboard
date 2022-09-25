/*********
SQL to create query for insertion into results table. These may be unioned together prior to insert.
Note that this does not include information about SQL errors or performance.
**********/

SELECT 
  cte.num_violated_rows
  ,cte.pct_violated_rows
  ,cte.num_denominator_rows
  ,'' as execution_time
  ,'Query # @query_num' as query_text
  ,'@check_name' as check_name
  ,'@check_level' as check_level
  ,'@check_description' as check_description
  ,'@cdm_table_name' as cdm_table_name
  ,'@cdm_field_name' as cdm_field_name
  ,'@concept_id' as concept_id
  ,'@unit_concept_id' as unit_concept_id
  ,'@sql_file' as sql_file
  ,'@category' as category
  ,'@subcategory' as subcategory
  ,'@context' as context
  ,'' as warning
  ,'' as error
  ,'@checkid' as checkid
  ,0 as is_error
  ,0 as not_applicable
  ,CASE WHEN (cte.pct_violated_rows * 100) > @threshold_value THEN 1 ELSE 0 END as failed
  ,CASE WHEN (cte.pct_violated_rows * 100) > @threshold_value THEN 0 ELSE 1 END as passed
  ,NULL as not_applicable_reason
  ,@threshold_value as threshold_value
  ,'' as notes_value
FROM (
  @query_text
) cte
