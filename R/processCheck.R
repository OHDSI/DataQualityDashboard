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

#' Internal function to send the fully qualified sql to the database and return the numerical result.
#'
#' @param connection                A connection for connecting to the CDM database using the DatabaseConnector::connect(connectionDetails) function.
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database.
#' @param check                     The data quality check
#' @param checkDescription          The description of the data quality check
#' @param sql                       The fully qualified sql for the data quality check
#' @param outputFolder              The folder to output logs and SQL files to.
#'
#' @keywords internal
#'

.processCheck <- function(connection,
                          connectionDetails,
                          check,
                          checkDescription,
                          sql,
                          outputFolder) {
  singleThreaded <- TRUE
  start <- Sys.time()
  if (is.null(connection)) {
    singleThreaded <- FALSE
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    on.exit(DatabaseConnector::disconnect(connection = connection))
  }

  errorReportFile <- file.path(
    outputFolder, "errors",
    sprintf(
      "%s_%s_%s_%s.txt",
      checkDescription$checkLevel,
      checkDescription$checkName,
      check["cdmTableName"],
      check["cdmFieldName"]
    )
  )
  tryCatch(
    expr = {
      if (singleThreaded) {
        if (.needsAutoCommit(connectionDetails = connectionDetails, connection = connection)) {
          rJava::.jcall(connection@jConnection, "V", "setAutoCommit", TRUE)
        }
      }
      result <- DatabaseConnector::querySql(
        connection = connection, sql = sql,
        errorReportFile = errorReportFile,
        snakeCaseToCamelCase = TRUE
      )

      delta <- difftime(Sys.time(), start, units = "secs")
      .recordResult(
        result = result, check = check, checkDescription = checkDescription, sql = sql,
        executionTime = sprintf("%f %s", delta, attr(delta, "units"))
      )
    },
    warning = function(w) {
      ParallelLogger::logWarn(sprintf(
        "[Level: %s] [Check: %s] [CDM Table: %s] [CDM Field: %s] %s",
        checkDescription$checkLevel,
        checkDescription$checkName,
        check["cdmTableName"],
        check["cdmFieldName"], w$message
      ))
      .recordResult(check = check, checkDescription = checkDescription, sql = sql, warning = w$message)
    },
    error = function(e) {
      ParallelLogger::logError(sprintf(
        "[Level: %s] [Check: %s] [CDM Table: %s] [CDM Field: %s] %s",
        checkDescription$checkLevel,
        checkDescription$checkName,
        check["cdmTableName"],
        check["cdmFieldName"], e$message
      ))
      .recordResult(check = check, checkDescription = checkDescription, sql = sql, error = e$message)
    }
  )
}
