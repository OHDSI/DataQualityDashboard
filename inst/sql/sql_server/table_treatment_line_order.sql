/*********
Table Level:  
TREATMENT_LINE_ORDER
Determine what #/% of treatment line records are in the wrong order (start date ranking doesn't correspond to TL number)

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema

**********/

SELECT num_violated_rows, 
	CASE 
		WHEN denominator.num_rows = 0 
		THEN 0 
		ELSE 1.0*num_violated_rows/denominator.num_rows 
		END AS pct_violated_rows, 
  	denominator.num_rows as num_denominator_rows
FROM
(
	SELECT count(distinct uniqueTLs) AS num_violated_rows from
	(SELECT
		distinct 
		tl.treatment_line_id as uniqueTLs, 
		tl.person_id,
		tl.line_number,
		tl.line_start_date,
		tl.line_end_date,
		tl2.treatment_line_id,
		tl2.line_number,
		tl2.line_start_date,
		tl2.line_end_date
	FROM @cdmDatabaseSchema.treatment_line tl 
	JOIN @cdmDatabaseSchema.treatment_line tl2 
	ON tl.person_id = tl2.person_id AND tl.line_number <> tl2.line_number 
	WHERE 
	tl.line_start_date > tl2.line_start_date AND tl.line_number < tl2.line_number
	)violated_rows
	) violated_row_count,
( 
	SELECT COUNT(*) AS num_rows
	FROM 
	(
		SELECT * FROM @cdmDatabaseSchema.treatment_line tl3 
	) as results_table	
) denominator;
