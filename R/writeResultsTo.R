# Copyright 2025 Observational Health Data Sciences and Informatics
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

#' Write DQD results to json
#'
#' @param result           A DQD results object (list)
#' @param outputFolder     The output folder
#' @param outputFile       The output filename

#' @keywords internal

.writeResultsToJson <- function(result,
                                outputFolder,
                                outputFile) {
  resultJson <- jsonlite::toJSON(result)

  resultFilename <- file.path(outputFolder, outputFile)
  result$outputFile <- outputFile

  ParallelLogger::logInfo(sprintf("Writing results to file: %s", resultFilename))
  write(resultJson, file = resultFilename)
}

#' Internal function to write the check results to a table in the database. Requires write access to the database
#'
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param checkResults              A dataframe containing the fully summarized data quality check results
#' @param writeTableName            The name of the table to be written to the database. Default is "dqdashboard_results".
#' @param cohortDefinitionId        (OPTIONAL) The cohort definition id for the cohort you wish to run the DQD on. The package assumes a standard OHDSI cohort table called 'Cohort'
#'                                  with the fields cohort_definition_id and subject_id.
#' @keywords internal

.writeResultsToTable <- function(connectionDetails,
                                 resultsDatabaseSchema,
                                 checkResults,
                                 writeTableName,
                                 cohortDefinitionId) {
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))

  if (length(cohortDefinitionId > 0)) {
    tableName <- sprintf("%s.%s_%s", resultsDatabaseSchema, writeTableName, cohortDefinitionId)
  } else {
    tableName <- sprintf("%s.%s", resultsDatabaseSchema, writeTableName)
  }

  ParallelLogger::logInfo(sprintf("Writing results to table %s", tableName))

  ddl <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "result_dataframe_ddl.sql",
    packageName = "DataQualityDashboard",
    tableName = tableName,
    dbms = connectionDetails$dbms
  )

  DatabaseConnector::executeSql(
    connection = connection,
    sql = ddl,
    progressBar = TRUE
  )

  # convert column names to snake case, omitting the checkId column,
  # which has no underscore in the results table DDL
  for (i in seq_len(ncol(checkResults))) {
    if (colnames(checkResults)[i] == "checkId") {
      colnames(checkResults)[i] <- tolower(colnames(checkResults)[i])
    } else {
      colnames(checkResults)[i] <- SqlRender::camelCaseToSnakeCase(colnames(checkResults)[i])
    }
  }

  tryCatch(
    expr = {
      DatabaseConnector::insertTable(
        connection = connection, tableName = tableName, data = checkResults,
        dropTableIfExists = FALSE, createTable = FALSE, tempTable = FALSE
      )
      ParallelLogger::logInfo("Finished writing table")
    },
    error = function(e) {
      warning(sprintf("Writing table failed: %s", e$message))
      ParallelLogger::logError(sprintf("Writing table failed: %s", e$message))
    }
  )
}

#' Internal function to write the check results to a csv file.
#'
#' @param checkResults              A dataframe containing the fully summarized data quality check results
#' @param csvPath                   The path where the csv file should be written
#' @param columns                   The columns to be included in the csv file. Default is all columns in the checkResults dataframe.
#' @param delimiter                 The delimiter for the file. Default is comma.
#'
#' @keywords internal

.writeResultsToCsv <- function(checkResults,
                               csvPath,
                               columns = c(
                                 "checkId", "failed", "passed",
                                 "isError", "notApplicable",
                                 "checkName", "checkDescription",
                                 "thresholdValue", "notesValue",
                                 "checkLevel", "category",
                                 "subcategory", "context",
                                 "checkLevel", "cdmTableName",
                                 "cdmFieldName", "conceptId",
                                 "unitConceptId", "numViolatedRows",
                                 "pctViolatedRows", "numDenominatorRows",
                                 "executionTime", "notApplicableReason",
                                 "error", "queryText"
                               ),
                               delimiter = ",") {
  tryCatch(
    expr = {
      ParallelLogger::logInfo(sprintf("Writing results to CSV file %s", csvPath))
      columns <- intersect(union(c("checkId", "failed", "passed", "isError", "notApplicable"), columns), colnames(checkResults))
      if (is.element("queryText", columns)) {
        checkResults$queryText <- stringr::str_replace_all(checkResults$queryText, "\n", " ")
        checkResults$queryText <- stringr::str_replace_all(checkResults$queryText, "\r", " ")
        checkResults$queryText <- stringr::str_replace_all(checkResults$queryText, "\t", " ")
      }
      if (is.element("error", columns)) {
        checkResults$error <- stringr::str_replace_all(checkResults$error, "\n", " ")
        checkResults$error <- stringr::str_replace_all(checkResults$error, "\r", " ")
        checkResults$error <- stringr::str_replace_all(checkResults$error, "\t", " ")
      }
      write.table(dplyr::select(checkResults, all_of(columns)), file = csvPath, sep = delimiter, row.names = FALSE, na = "")
      ParallelLogger::logInfo("Finished writing to CSV file")
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("Writing to CSV file failed: %s", e$message))
    }
  )
}
