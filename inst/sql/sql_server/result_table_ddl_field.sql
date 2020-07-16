--DDL to create dqdashboard_results table.

DROP TABLE IF EXISTS @tableName;
CREATE TABLE @tableName
(
  num_violated_rows     integer,
  pct_violated_rows     float8,
  num_denominator_rows  integer,
  execution_time        varchar(255),
  query_text            varchar(MAX),
  check_name            varchar(255),
  check_level           varchar(255),
  check_description     varchar(MAX),
  cdm_table_name        varchar(255),
  cdm_field_name        varchar(255),
  sql_file              varchar(255),
  category              varchar(255),
  subcategory           varchar(255),
  context               varchar(255),
  checkid               integer,
  failed                integer,
  threshold_value       integer,
  x_row                 varchar(255)
);