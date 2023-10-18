# Copyright 2023 Observational Health Data Sciences and Informatics
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
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param cdmDatabaseSchema         The fully qualified database name of the CDM schema
#' @param writeTableName            Name of table in the database to write results to
#' @param outputFolder              The output folder
#' @param outputFile                The output filename
#'
#' @export
#'

writeDBResultsToJson <- function(connection,
                                    connectionDetails,
                                    resultsDatabaseSchema,
                                    cdmDatabaseSchema,
                                    writeTableName,
                                    outputFolder,
                                    outputFile) {
    startTime <- Sys.time()

    sql <- SqlRender::render(
          sql = "select * from @cdmDatabaseSchema.cdm_source;",
          cdmDatabaseSchema = cdmDatabaseSchema
        )

    sql <- SqlRender::translate(
         sql = sql,
         targetDialect = connectionDetails$dbms
        )

    metadata <- DatabaseConnector::querySql(
         connection = connection,
         sql = sql,
         snakeCaseToCamelCase = TRUE
        )

    sql <- SqlRender::render(
          sql = "select * from @resultsDatabaseSchema.@writeTableName;",
          resultsDatabaseSchema = resultsDatabaseSchema,
          writeTableName = writeTableName
        )

    sql <- SqlRender::translate(
          sql = sql,
          targetDialect = connectionDetails$dbms
         )

    checkResults <- DatabaseConnector::querySql(
         connection,
         sql,
         snakeCaseToCamelCase = TRUE
        )

    # Quick patch for missing value issues related to SQL Only Implementation
    checkResults["error"][checkResults["error"] == ''] <- NA
    checkResults["warning"][checkResults["warning"] == ''] <- NA
    checkResults["executionTime"][checkResults["executionTime"] == ''] <- '0.1 secs'
    checkResults["queryText"][checkResults["queryText"] == ''] <- '[Generated via SQL Only]'

    overview <- .summarizeResults(
        checkResults = checkResults
        )

    endTime <- Sys.time()

    delta <- startTime - endTime

    # Quick patch for non-camel-case column name
    names(checkResults)[names(checkResults) == "checkid"] <- "checkId"

    allResults <- list(
        startTimestamp = Sys.time(),
        endTimestamp = Sys.time(),
        executionTime = sprintf("%.0f %s", delta, attr(delta, "units")),
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