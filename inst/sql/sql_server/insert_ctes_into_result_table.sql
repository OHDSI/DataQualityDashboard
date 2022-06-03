/*********
SQL to insert individual DQD results directly into output table (rather than waiting until collect all results.
Note that this  does not include information about SQL errors or performance

Parameters used in this template:
resultsDatabaseSchema = @resultsDatabaseSchema
tableName = @tableName
query_text = @query_text
**********/

WITH cte_all AS (
  @query_text
)
INSERT INTO @resultsDatabaseSchema.@tableName
SELECT *
FROM cte_all
;