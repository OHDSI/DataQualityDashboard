# Copyright 2026 Observational Health Data Sciences and Informatics
#
# This file is part of DataQualityDashboard
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Execute DQD for extension tables, using custom threshold files in long format.
#' 
#' This function is a wrapper around DQD::executeDqChecks that allows for using the long-format threshold files.
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param cdmDatabaseSchema         The fully qualified database name of the CDM schema. All extension tables must be in this schema.
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param vocabDatabaseSchema       The fully qualified database name of the vocabulary schema (default is to set it as the cdmDatabaseSchema)
#' @param numThreads                The number of concurrent threads to use to execute the queries
#' @param cdmSourceName             The name of the CDM data source
#' @param tableCheckThresholdExtensionLoc   The location of the long-format threshold file for the table-level checks for the extension tables
#' @param fieldCheckThresholdExtensionLoc   The location of the long-format threshold file for the field-level checks for the extension tables
#' @param conceptCheckThresholdExtensionLoc The location of the long-format threshold file for the concept-level checks for the extension tables
#' @param sqlOnly                   Should the SQLs be executed (FALSE) or just returned (TRUE)?
#' @param sqlOnlyUnionCount         (OPTIONAL) In sqlOnlyIncrementalInsert mode, how many SQL commands to union in each query to insert check results into results table (can speed processing when queries done in parallel). Default is 1.
#' @param sqlOnlyIncrementalInsert  (OPTIONAL) In sqlOnly mode, boolean to determine whether to generate SQL queries that insert check results and associated metadata into results table.  Default is FALSE (for backwards compatibility to <= v2.2.0)
#' @param outputFolder              The folder to output logs, SQL files, and JSON results file to
#' @param outputFile                (OPTIONAL) File to write results JSON object
#' @param verboseMode               Boolean to determine if the console will show all execution steps. Default is FALSE
#' @param writeToTable              Boolean to indicate if the check results will be written to the dqdashboard_results table in the resultsDatabaseSchema. Default is TRUE
#' @param writeTableName            The name of the results table. Defaults to `dqdashboard_results`.  Used when sqlOnly or writeToTable is True.
#' @param writeToCsv                Boolean to indicate if the check results will be written to a csv file. Default is FALSE
#' @param csvFile                   (OPTIONAL) CSV file to write results
#' @param checkLevels               Choose which DQ check levels to execute. Default is all 3 (TABLE, FIELD, CONCEPT)
#' @param checkSeverity             Choose which DQ check severity levels to execute. Default is all 3 (fatal, convention, characterization)
#' @param checkNames                (OPTIONAL) Choose which check names to execute. Names can be found in inst/csv/OMOP_CDM_v[cdmVersion]_Check_Descriptions.csv. Note that "cdmTable", "cdmField" and "measureValueCompleteness" are always executed.
#' @param cohortDefinitionId        The cohort definition id for the cohort you wish to run the DQD on. The package assumes a standard OHDSI cohort table
#'                                  with the fields cohort_definition_id and subject_id.
#' @param cohortDatabaseSchema      The schema where the cohort table is located.
#' @param cohortTableName           The name of the cohort table. Defaults to `cohort`.
#' @param tablesToExclude           (OPTIONAL) Choose which CDM tables to exclude from the execution.
#' @param cdmVersion                The CDM version to target for the data source. Options are "5.2", "5.3", or "5.4". By default, "5.3" is used.
#' @param tableCheckThresholdLoc    The location of the threshold file for evaluating the table checks. If not specified the default thresholds will be applied.
#' @param fieldCheckThresholdLoc    The location of the threshold file for evaluating the field checks. If not specified the default thresholds will be applied.
#' @param conceptCheckThresholdLoc  The location of the threshold file for evaluating the concept checks. If not specified the default thresholds will be applied.
#'
#' @importFrom DataQualityDashboard executeDqChecks
#' @importFrom utils packageVersion getFromNamespace
#' @return dqd results object
#' @export
executeDqChecksOnExtension <- function(
  connectionDetails,
  cdmDatabaseSchema,
  resultsDatabaseSchema,
  vocabDatabaseSchema = cdmDatabaseSchema,
  cdmSourceName,
  tableCheckThresholdExtensionLoc = NULL,
  fieldCheckThresholdExtensionLoc = NULL,
  conceptCheckThresholdExtensionLoc = NULL,
  numThreads = 1,
  sqlOnly = FALSE,
  sqlOnlyUnionCount = 1,
  sqlOnlyIncrementalInsert = FALSE,
  outputFolder,
  outputFile = "",
  verboseMode = FALSE,
  writeToTable = TRUE,
  writeTableName = "dqdashboard_results",
  writeToCsv = FALSE,
  csvFile = "",
  checkLevels = c("TABLE", "FIELD", "CONCEPT"),
  checkNames = c(),
  checkSeverity = c("fatal", "convention", "characterization"),
  cohortDefinitionId = c(),
  cohortDatabaseSchema = resultsDatabaseSchema,
  cohortTableName = "cohort",
  tablesToExclude = c("CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN"),
  cdmVersion = "5.3"
) {
  hasThresholdFile <- function(path) {
    !is.null(path) && length(path) == 1 && !is.na(path) && nzchar(path)
  }

  # Transform long-format threshold files to wide-format and write to temporary files -------------------
  tableCheckThresholdLoc <- "default"
  fieldCheckThresholdLoc <- "default"
  conceptCheckThresholdLoc <- "default"
  availableCheckLevels <- character(0)

  if ("TABLE" %in% checkLevels && hasThresholdFile(tableCheckThresholdExtensionLoc)) {
    tableCheckThresholdLoc <- tempfile(fileext = ".csv")
    .pivotTableLevelThreshold(
      in_path = tableCheckThresholdExtensionLoc,
      out_path = tableCheckThresholdLoc
    )
    availableCheckLevels <- c(availableCheckLevels, "TABLE")
  }

  if ("FIELD" %in% checkLevels && hasThresholdFile(fieldCheckThresholdExtensionLoc)) {
    fieldCheckThresholdLoc <- tempfile(fileext = ".csv")
    .pivotFieldLevelThreshold(
      in_path = fieldCheckThresholdExtensionLoc,
      out_path = fieldCheckThresholdLoc
    )
    availableCheckLevels <- c(availableCheckLevels, "FIELD")
  }

  if ("CONCEPT" %in% checkLevels && hasThresholdFile(conceptCheckThresholdExtensionLoc)) {
    conceptCheckThresholdLoc <- tempfile(fileext = ".csv")
    .pivotConceptLevelThreshold(
      in_path = conceptCheckThresholdExtensionLoc,
      out_path = conceptCheckThresholdLoc
    )
    availableCheckLevels <- c(availableCheckLevels, "CONCEPT")
  }

  if (is.null(checkLevels)) {
    checkLevels <- availableCheckLevels
  } else {
    checkLevels <- intersect(checkLevels, availableCheckLevels)
  }

  if (length(checkLevels) == 0) {
    stop("No extension threshold file locations were provided for the requested check levels.")
  }

  results <- executeDqChecks(
    connectionDetails = connectionDetails, 
    cdmDatabaseSchema = cdmDatabaseSchema, 
    resultsDatabaseSchema = resultsDatabaseSchema,
    vocabDatabaseSchema = vocabDatabaseSchema,
    cdmSourceName = cdmSourceName,
    numThreads = numThreads,
    sqlOnly = sqlOnly,
    sqlOnlyUnionCount = sqlOnlyUnionCount,
    sqlOnlyIncrementalInsert = sqlOnlyIncrementalInsert,
    outputFolder = outputFolder,
    outputFile = outputFile,
    verboseMode = verboseMode,
    writeToTable = writeToTable,
    writeTableName = writeTableName,
    writeToCsv = writeToCsv,
    csvFile = csvFile,
    checkLevels = checkLevels,
    checkNames = checkNames,
    checkSeverity = checkSeverity,
    cohortDefinitionId = cohortDefinitionId,
    cohortDatabaseSchema = cohortDatabaseSchema,
    cohortTableName = cohortTableName,
    tablesToExclude = tablesToExclude,
    cdmVersion = cdmVersion,
    tableCheckThresholdLoc = tableCheckThresholdLoc,
    fieldCheckThresholdLoc = fieldCheckThresholdLoc,
    conceptCheckThresholdLoc = conceptCheckThresholdLoc
  )

  invisible(results)
}


#' Reads the Table-level DQD Thresholds file in long format and writes it in wide format. 
#' The long format is more human readable and easier to maintain, but the wide format is expected for DQD.
#' @param in_path Input path with long-format thresholds file
#' @param out_path Output path to write wide-format thresholds file to
#' @return NULL
#' @importFrom dplyr rename
#' @importFrom readr write_csv
#' @noRd
.pivotTableLevelThreshold <- function(in_path, out_path) {
  .pivot(
    in_path,
    values_from = c('checkParameter', 'Threshold', 'Notes')    
  ) |>
  write_csv(
    out_path,
    col_names = TRUE,
    na = ""
  )
}

#' Reads the Field-level DQD Thresholds file in long format and writes it in wide format. 
#' The long format is more human readable and easier to maintain, but the wide format is expected for DQD.
#' @param in_path Input path with long-format thresholds file
#' @param out_path Output path to write wide-format thresholds file to
#' @return NULL
#' @importFrom dplyr rename
#' @importFrom readr write_csv
#' @noRd
.pivotFieldLevelThreshold <- function(in_path, out_path) {
  .pivot(
    in_path,
    values_from = c('checkParameter', 'Threshold', 'Notes', 'checkParameter_TableName', 'checkParameter_FieldName')
  ) |>
  rename(
    fkTableName = isForeignKeyTableName,
    fkFieldName = isForeignKeyFieldName,
    standardConceptFieldName = sourceValueCompletenessFieldName
  ) |>
  write_csv(
    out_path,
    col_names = TRUE,
    na = ""
  )
}

#' Reads the Concept-level DQD Thresholds file in long format and writes it in wide format. 
#' The long format is more human readable and easier to maintain, but the wide format is expected for DQD.
#' NOTE: only tested for 'plausibleGenderUseDescendants'
#' @param in_path Input path with long-format thresholds file
#' @param out_path Output path to write wide-format thresholds file to
#' @return NULL
#' @importFrom dplyr rename
#' @importFrom readr write_csv
#' @noRd
.pivotConceptLevelThreshold <- function(in_path, out_path) {
  .pivot(
    in_path,
    # The following are not parameters, but just like table and field they are keys to pivot by
    # 'checkParameter_conceptId', 'checkParameter_conceptName', 'checkParameter_unitConceptId', 'checkParameter_unitConceptName'
    values_from = c('checkParameter', 'Threshold', 'Notes')
  ) |> 
  rename(
    plausibleGenderUseDescendantsconceptId = conceptId,
    plausibleGenderUseDescendantsconceptName = conceptName
  ) |>
  write_csv(
    out_path,
    col_names = TRUE,
    na = ""
  )
}

#' Generic function for DQD Threshold long to wide format.
#' @param in_path Input path with long-format thresholds file
#' @param values_from list of column names to pivot, differs per check level
#' @return thresholds table in wide format
#' @importFrom dplyr mutate coalesce select_if all_of rename_with
#' @importFrom tidyr pivot_wider
#' @noRd
.pivot <- function(in_path, values_from) {
  longLevel <- read_csv(in_path, show_col_types = FALSE)

  if (!('checkParameter' %in% names(longLevel))) {
    longLevel$checkParameter <- NA
  }

  wideLevel <- longLevel |>
    mutate(
      checkParameter = coalesce(checkParameter, 'Yes'),
      Notes = coalesce(Notes, '')
    ) |>
    pivot_wider(
      names_from = checkName,
      names_glue = '{checkName}{.value}',
      values_from = all_of(values_from),
      names_sort = TRUE,
      values_fill = list(checkParameter = NA, Notes = '')
    )

  wideLevel |>
    rename_with(
      ~ sub('checkParameter_?', '', .x)
    ) |>
    select_if(
      function(x) !(all(is.na(x)))
    )
}
