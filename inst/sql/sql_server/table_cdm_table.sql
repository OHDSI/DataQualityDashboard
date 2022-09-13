
/*********
TABLE LEVEL check:
CDM_TABLE - verify the table exists

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName

**********/


SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
  select num_violated_rows from
  (
    select
      case when count_big(*) = 0 then 0
      else 0
    end as num_violated_rows
    from @cdmDatabaseSchema.@cdmTableName cdmTable
  ) violated_rows
) violated_row_count,
( 
	SELECT 1 as num_rows
) denominator
;