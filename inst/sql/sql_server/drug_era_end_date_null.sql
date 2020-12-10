/*********
Table Level:
Drug_era_end_date_null
Determine what #/% of drug_era_end_dates are null when not being in the latest regimen

Parameters used in this template:
cdmDatabaseSchema = @cdmDatabaseSchema
cdmTableName = @cdmTableName

**********/
SELECT num_violated_rows,
       CASE
           WHEN denominator.num_rows = 0 THEN 0
           ELSE 1.0*num_violated_rows/denominator.num_rows
       END AS pct_violated_rows,
       denominator.num_rows as num_denominator_rows
FROM
    ( SELECT count(*) AS num_violated_rows
     from
         (SELECT *
          FROM @cdmDatabaseSchema.@cdmTableName m
          LEFT JOIN
              ( SELECT m2.person_id,
                       max(m2.drug_era_start_date) AS latest_start_date
               FROM @cdmDatabaseSchema.@cdmTableName m2
               GROUP BY m2.person_id) max_start ON max_start.person_id = m.person_id
          WHERE drug_era_end_date IS NULL
              AND line_start_date < latest_start_date )violated_rows ) violated_row_count,

    (SELECT COUNT(*) AS num_rows
     FROM
         ( SELECT *
          FROM @cdmDatabaseSchema.@cdmTableName tl3 where drug_era_end_date is null) as results_table) denominator;

