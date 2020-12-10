/*********
Table Level:  
periods within boundaries
Determine what #/% of records are not within the given boundaries. 

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName
idField = @idField
startDateField = @startDateField
endDateField = @endDateField
lowerBoundary = @lowerBoundary
upperBoundary = @upperBoundary
countUnique = @countUnique
**********/

SELECT num_violated_rows, CASE WHEN denominator.num_rows = 0 THEN 0 ELSE 1.0*num_violated_rows/denominator.num_rows END AS pct_violated_rows, 
  denominator.num_rows as num_denominator_rows
FROM
(
	SELECT count(distinct @countUnique) AS num_violated_rows from
		(SELECT * FROM @cdmDatabaseSchema.@cdmTableName
            WHERE not ((@startDateField >= @lowerBoundary AND @endDateField <= @upperBoundary AND @startDateField <= @endDateField and @endDateField is not null)
            OR (@startDateField >= @lowerBoundary and @endDateField is null))
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