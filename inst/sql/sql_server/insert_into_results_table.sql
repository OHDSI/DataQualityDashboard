/*********
SQL to insert individual DQD results directly into output table (rather than waiting until collect all results.
Note that this  does not include information about SQL errors or performance

Parameters used in this template:
tableName = @tableName
query_text = @query_text
check_name = @check_name
check_level = @check_level
check_description = @check_description
cdm_table_name = @cdm_table_name
cdm_field_name = @cdm_field_name
concept_id = @concept_id
unit_concept_id = @unit_concept_id
sql_file = @sql_file
category = @category
subcategory = @subcategory
context = @context
checkid = @checkid
threshold_value = @threshold_value
**********/

WITH cte AS (
  @query_text
)
INSERT INTO @tableName
SELECT 
  cte.num_violated_rows
  ,cte.pct_violated_rows
  ,cte.num_denominator_rows
  ,'' as execution_time
  ,'' as query_text
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
  ,CASE WHEN (cte.pct_violated_rows * 100) > @threshold_value THEN 1 ELSE 0 END as failed
  ,@threshold_value as threshold_value
  ,'' as notes_value
FROM cte
;
