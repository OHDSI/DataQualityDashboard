--DDL to create dqdashboard_results table.

IF OBJECT_ID('@tableName', 'U') IS NOT NULL
	DROP TABLE @tableName;  
CREATE TABLE @tableName
(
  num_violated_rows     bigint,
  pct_violated_rows     float,
  num_denominator_rows  bigint,
  execution_time        varchar(255),
  query_text            varchar(8000),
  check_name            varchar(255),
  check_level           varchar(255),
  check_description     varchar(8000),
  cdm_table_name        varchar(255),
  sql_file              varchar(255),
  category              varchar(255),
  subcategory           varchar(255),
  context               varchar(255),
  checkid               varchar(1024),
  failed                integer,
  threshold_value       integer,
  notes_value           varchar(8000),
  x_row                 varchar(255),
  cdm_field_name        varchar(255),
  error                 varchar(8000),
  concept_id            varchar(255),
  unit_concept_id       varchar(255)
);