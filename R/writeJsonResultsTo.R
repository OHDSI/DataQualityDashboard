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

#' Write JSON Results to SQL Table
#'
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param jsonFilePath              Path to the JSON results file generated using the execute function
#' @param writeTableName            Name of table in the database to write results to
#' @param cohortDefinitionId        If writing results for a single cohort this is the ID that will be appended to the table name
#' @param singleTable               If TRUE, writes all results to a single table. If FALSE (default), writes to 3 separate tables by check level (table, field, concept) (NOTE this default behavior will be deprecated in the future)
#'
#' @export

writeJsonResultsToTable <- function(connectionDetails,
                                    resultsDatabaseSchema,
                                    jsonFilePath,
                                    writeTableName = "dqdashboard_results",
                                    cohortDefinitionId = c(),
                                    singleTable = FALSE) {
  jsonData <- jsonlite::read_json(jsonFilePath)
  checkResults <- lapply(jsonData$CheckResults, function(cr) {
    cr[sapply(cr, is.null)] <- NA
    as.data.frame(cr)
  })
  df <- do.call(plyr::rbind.fill, checkResults)

  if (singleTable) {
    # Write all results to a single table
    .writeResultsToTable(
      connectionDetails = connectionDetails,
      resultsDatabaseSchema = resultsDatabaseSchema,
      checkResults = df,
      writeTableName = writeTableName,
      cohortDefinitionId = cohortDefinitionId
    )
  } else {
    # Write to 3 separate tables by check level (backward compatibility)
    warning("Writing to 3 separate tables by check level is deprecated and will be removed in a future version. Use singleTable = TRUE to write DQD results to a single table.")

    # Split results by check level
    tableLevelResults <- df[df$checkLevel == "TABLE", ]
    fieldLevelResults <- df[df$checkLevel == "FIELD", ]
    conceptLevelResults <- df[df$checkLevel == "CONCEPT", ]

    # Write table-level results
    if (nrow(tableLevelResults) > 0) {
      tableTableName <- paste0(writeTableName, "_table")
      .writeResultsToTable(
        connectionDetails = connectionDetails,
        resultsDatabaseSchema = resultsDatabaseSchema,
        checkResults = tableLevelResults,
        writeTableName = tableTableName,
        cohortDefinitionId = cohortDefinitionId
      )
    }

    # Write field-level results
    if (nrow(fieldLevelResults) > 0) {
      fieldTableName <- paste0(writeTableName, "_field")
      .writeResultsToTable(
        connectionDetails = connectionDetails,
        resultsDatabaseSchema = resultsDatabaseSchema,
        checkResults = fieldLevelResults,
        writeTableName = fieldTableName,
        cohortDefinitionId = cohortDefinitionId
      )
    }

    # Write concept-level results
    if (nrow(conceptLevelResults) > 0) {
      conceptTableName <- paste0(writeTableName, "_concept")
      .writeResultsToTable(
        connectionDetails = connectionDetails,
        resultsDatabaseSchema = resultsDatabaseSchema,
        checkResults = conceptLevelResults,
        writeTableName = conceptTableName,
        cohortDefinitionId = cohortDefinitionId
      )
    }
  }
}


#' Write JSON Results to CSV file
#'
#' @param jsonPath    Path to the JSON results file generated using the execute function
#' @param csvPath     Path to the CSV output file
#' @param columns     (OPTIONAL) List of desired columns
#' @param delimiter   (OPTIONAL) CSV delimiter
#'
#' @export

writeJsonResultsToCsv <- function(jsonPath,
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
      ParallelLogger::logInfo(sprintf("Loading results from %s", jsonPath))
      jsonData <- jsonlite::read_json(jsonPath)
      checkResults <- lapply(jsonData$CheckResults, function(cr) {
        cr[sapply(cr, is.null)] <- NA
        as.data.frame(cr)
      })
      .writeResultsToCsv(
        checkResults = do.call(plyr::rbind.fill, checkResults),
        csvPath = csvPath,
        columns = columns,
        delimiter = delimiter
      )
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("Writing to CSV file failed: %s", e$message))
    }
  )
}
