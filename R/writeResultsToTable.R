# @file writeResultsToTable.R
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
#' If in the executeDqChecks function the parameter writeToTable is set to true, this function will
#' write a table to the results schema with the results of the data quality checks.
#' 
#' @param connectionDetails A connectionDetails object for connecting to the CDM database
#' @param resultsDatabaseSchema The schema where the table with the data quality checks should be written
#' @param checkResults The data frame with the results of the data quality checks
#' 
#' 

.writeResultsToTable <- function(connectionDetails,
                                 resultsDatabaseSchema,
                                 checkResults) {
  
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))
  tableName <- sprintf("%s.dqdashboard_results", resultsDatabaseSchema)
  
  ParallelLogger::logInfo(sprintf("Writing results to table %s", tableName))
  
  tryCatch(
    expr = {
      DatabaseConnector::insertTable(connection = connection, tableName = tableName, data = checkResults, 
                                     dropTableIfExists = TRUE, createTable = TRUE, tempTable = FALSE)
      ParallelLogger::logInfo("Finished writing table")
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("Writing table failed: %s", e$message))
    }
  )
}