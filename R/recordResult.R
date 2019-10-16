# @file recordResult.R
#
# Copyright 2019 Observational Health Data Sciences and Informatics
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


#' SUPPORT FUNCTION 
#' referenced in execution.R
#' 
#' Creates an dataframe with the results of the data quality checks.
#' 
#' 
#'

.recordResult <- function(result = NULL, check, 
                          checkDescription, sql, 
                          executionTime = NA,
                          warning = NA, error = NA) {
  
  columns <- lapply(names(check), function(c) {
    setNames(check[c], c)
  })
  
  params <- c(list(sql = checkDescription$checkDescription),
              list(warnOnMissingParameters = FALSE),
              unlist(columns, recursive = FALSE))
  
  reportResult <- data.frame(
    NUM_VIOLATED_ROWS = NA,
    PCT_VIOLATED_ROWS = NA,
    EXECUTION_TIME = executionTime,
    QUERY_TEXT = sql,
    CHECK_NAME = checkDescription$checkName,
    CHECK_LEVEL = checkDescription$checkLevel,
    CHECK_DESCRIPTION = do.call(SqlRender::render, params),
    CDM_TABLE_NAME = check["cdmTableName"],
    CDM_FIELD_NAME = check["cdmFieldName"],
    CONCEPT_ID = check["conceptId"],
    UNIT_CONCEPT_ID = check["unitConceptId"],
    SQL_FILE = checkDescription$sqlFile,
    CATEGORY = checkDescription$kahnCategory,
    SUBCATEGORY = checkDescription$kahnSubcategory,
    CONTEXT = checkDescription$kahnContext,
    WARNING = warning,
    ERROR = error, row.names = NULL, stringsAsFactors = FALSE
  )
  
  if (!is.null(result)) {
    reportResult$NUM_VIOLATED_ROWS <- result$NUM_VIOLATED_ROWS
    reportResult$PCT_VIOLATED_ROWS <- result$PCT_VIOLATED_ROWS
  }
  reportResult
}