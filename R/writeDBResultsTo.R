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

#' Write DQD results database table to json
#'
#' @param connection                A connection object
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param cdmDatabaseSchema         The fully qualified database name of the CDM schema
#' @param writeTableName            Name of DQD results table in the database to read from
#' @param outputFolder              The folder to output the json results file to
#' @param outputFile                The output filename of the json results file
#'
#' @export
#'

writeDBResultsToJson <- function(connection,
                                 resultsDatabaseSchema,
                                 cdmDatabaseSchema,
                                 writeTableName,
                                 outputFolder,
                                 outputFile) {
  metadata <- DatabaseConnector::renderTranslateQuerySql(
    connection,
    sql = "select * from @cdmDatabaseSchema.cdm_source;",
    snakeCaseToCamelCase = TRUE,
    cdmDatabaseSchema = cdmDatabaseSchema
  )

  checkResults <- DatabaseConnector::renderTranslateQuerySql(
    connection,
    sql = "select * from @resultsDatabaseSchema.@writeTableName;",
    snakeCaseToCamelCase = TRUE,
    resultsDatabaseSchema = resultsDatabaseSchema,
    writeTableName = writeTableName
  )

  # Quick patch for missing value issues related to SQL Only Implementation
  checkResults["error"][checkResults["error"] == ""] <- NA
  checkResults["warning"][checkResults["warning"] == ""] <- NA
  checkResults["executionTime"][checkResults["executionTime"] == ""] <- "0 secs"
  checkResults["queryText"][checkResults["queryText"] == ""] <- "[Generated via SQL Only]"

  overview <- .summarizeResults(
    checkResults = checkResults
  )

  # Quick patch for non-camel-case column name
  names(checkResults)[names(checkResults) == "checkid"] <- "checkId"

  allResults <- list(
    startTimestamp = Sys.time(),
    endTimestamp = Sys.time(),
    executionTime = "0 secs",
    CheckResults = checkResults,
    Metadata = metadata,
    Overview = overview
  )

  .writeResultsToJson(
    allResults,
    outputFolder,
    outputFile
  )
}
