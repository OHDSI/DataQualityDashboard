# @file writeJsonResultsToTable.R
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

#' After executing the data quality checks, this function will write JSON Results to a 
#' table in an SQL schema. 
#' 
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema where the table should be written
#' @param jsonFilePath              Path to the JSON results file with the data quality checks generated using the execute function
#' 
#' @export
writeJsonResultsToTable <- function(connectionDetails,
                                    resultsDatabaseSchema,
                                    jsonFilePath) {
  
  jsonData <- jsonlite::read_json(jsonFilePath)
  checkResults <- lapply(jsonData$CheckResults, function(cr) {
    cr[sapply(cr, is.null)] <- NA
    as.data.frame(cr)
  })
  
  df <- do.call(plyr::rbind.fill, checkResults)
  .writeResultsToTable(connectionDetails = connectionDetails,
                       resultsDatabaseSchema = resultsDatabaseSchema,
                       checkResults = df)
}
