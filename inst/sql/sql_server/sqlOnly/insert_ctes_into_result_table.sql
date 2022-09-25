/*********
SQL to insert individual DQD results directly into output table, rather than waiting until collecting all results.
Note that this  does not include information about SQL errors or performance
**********/

WITH cte_all AS (
  @query_text
)
INSERT INTO @resultsDatabaseSchema.@tableName
SELECT *
FROM cte_all
;