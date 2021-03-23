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
	(SELECT * FROM 	
		(SELECT 
			person_id, 
			min(drug_era_start_date) AS min_era, 
			line_number 
		FROM @cdmDatabaseSchema.treatment_line tl 
		GROUP BY tl.person_id, tl.line_number ) min_table
		LEFT JOIN 
		(SELECT 
			person_id, 
			line_number, 
			line_start_date 
		FROM @cdmDatabaseSchema.treatment_line tl2) tr_table 
		ON min_table.person_id = tr_table.person_id AND min_table.line_number = tr_table.line_number
		WHERE line_start_date != min_era
		) violated_rows
	) violated_row_count,
( 
	SELECT COUNT(*) AS num_rows
	FROM 
	(
		SELECT * FROM @cdmDatabaseSchema.treatment_line tl3 
	) as results_table	
) denominator;