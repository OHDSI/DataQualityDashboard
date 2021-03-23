/*********
Table Level:  
PERIOD OVERLAP
Determine what #/% of records overlap with another record.

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
idField = @idField
startDateField = @startDateField
endDateField = @endDateField
countUnique = @countUnique
**********/

SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT count(distinct unique_id) AS num_violated_rows from
		(SELECT 
			DISTINCT 
			m.@countUnique as unique_id,
			m.person_id,
			m.@idField,
			m.@startDateField,
			m.@endDateField,
			m2.@idField,
			m2.@startDateField,
			m2.@endDateField
		FROM @cdmDatabaseSchema.@cdmTableName m 
		JOIN
		@cdmDatabaseSchema.@cdmTableName m2 ON m.person_id = m2.person_id AND m.@idField <> m2.@idField
		WHERE 
		(m.@startDateField BETWEEN m2.@startDateField AND m2.@endDateField
				OR m.@endDateField BETWEEN m2.@startDateField AND m2.@endDateField
				OR m.@startDateField < m2.@startDateField AND m.@endDateField > m2.@endDateField
				OR m.@startDateField > m2.@startDateField AND m.@endDateField < m2.@endDateField)
				AND NOT ( ((m2.@endDateField = m.@startDateField) AND NOT  (m2.@startDateField = m.@endDateField) ) 
						OR ( NOT (m2.@endDateField = m.@startDateField) AND   (m2.@startDateField = m.@endDateField) ))
		) violated_rows
	) violated_row_count,
( 
	SELECT COUNT(*) AS num_rows
	FROM 
	(
		SELECT * FROM @cdmDatabaseSchema.@cdmTableName m3 
	) as results_table
) denominator
;