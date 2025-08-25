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

#' Internal function to put the results of each quality check into a dataframe.
#'
#' @param result                    The result of the data quality check
#' @param check                     The data quality check
#' @param checkDescription          The description of the data quality check
#' @param sql                       The fully qualified sql for the data quality check
#' @param executionTime             The total time it took to execute the data quality check
#' @param warning                   Any warnings returned from the server
#' @param error                     Any errors returned from the server
#'
#' @keywords internal
#' @importFrom stats setNames
#'


.recordResult <- function(result = NULL,
                          check,
                          checkDescription,
                          sql,
                          executionTime = NA,
                          warning = NA,
                          error = NA) {
  columns <- lapply(names(check), function(c) {
    setNames(check[c], c)
  })

  params <- c(
    list(sql = checkDescription$checkDescription),
    list(warnOnMissingParameters = FALSE),
    lapply(unlist(columns, recursive = FALSE), toupper)
  )

  reportResult <- data.frame(
    numViolatedRows = NA,
    pctViolatedRows = NA,
    numDenominatorRows = NA,
    executionTime = executionTime,
    queryText = sql,
    checkName = checkDescription$checkName,
    checkLevel = checkDescription$checkLevel,
    checkDescription = do.call(SqlRender::render, params),
    cdmTableName = check["cdmTableName"],
    cdmFieldName = check["cdmFieldName"],
    conceptId = check["conceptId"],
    unitConceptId = check["unitConceptId"],
    sqlFile = checkDescription$sqlFile,
    category = checkDescription$kahnCategory,
    subcategory = checkDescription$kahnSubcategory,
    context = checkDescription$kahnContext,
    warning = warning,
    error = error,
    checkId = .getCheckId(checkDescription$checkLevel, checkDescription$checkName, check["cdmTableName"], check["cdmFieldName"], check["conceptId"], check["unitConceptId"]),
    row.names = NULL, stringsAsFactors = FALSE
  )

  if (!is.null(result)) {
    reportResult$numViolatedRows <- result$numViolatedRows
    reportResult$pctViolatedRows <- result$pctViolatedRows
    reportResult$numDenominatorRows <- result$numDenominatorRows
  }
  reportResult
}
