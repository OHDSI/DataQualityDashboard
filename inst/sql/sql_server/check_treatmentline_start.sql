/*********
Table Level:  
TREATMENT_LINE_START
Determine what #/% of treatment line records have a starting date that doesn't correspond to the minimum drug era start date

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
	SELECT count(*) AS num_violated_rows from
	(SELECT
		distinct 
		tl.person_id,
		tl.line_number,
		tl.line_start_date!=min(tl.drug_era_start_date) as wrong
	FROM @cdmDatabaseSchema.treatment_line tl 
	group by line_number, person_id
	) violated_rows
	where wrong
	) violated_row_count,
( 
	SELECT COUNT(*) AS num_rows
	FROM 
	(
		SELECT * FROM @cdmDatabaseSchema.treatment_line tl3 
	) as results_table	
) denominator;