--DDL to create dqdashboard_results table.

IF OBJECT_ID('@tableName', 'U') IS NOT NULL
	DROP TABLE @tableName;  
CREATE TABLE @tableName
(
  num_violated_rows     BIGINT,
  pct_violated_rows     FLOAT,
  num_denominator_rows  BIGINT,
  execution_time        VARCHAR(255),
  query_text            VARCHAR(8000),
  check_name            VARCHAR(255),
  check_level           VARCHAR(255),
  check_description     VARCHAR(8000),
  cdm_table_name        VARCHAR(255),
  sql_file              VARCHAR(255),
  category              VARCHAR(255),
  subcategory           VARCHAR(255),
  context               VARCHAR(255),
  checkid               VARCHAR(1024),
  is_error              INTEGER,
  not_applicable        INTEGER,
  failed                INTEGER,
  passed                INTEGER,
  not_applicable_reason VARCHAR(8000),  
  threshold_value       INTEGER,
  notes_value           VARCHAR(8000),
  x_row                 VARCHAR(255),
  cdm_field_name        VARCHAR(255),
  error                 VARCHAR(8000),
  concept_id            VARCHAR(255),
  unit_concept_id       VARCHAR(255)
);
