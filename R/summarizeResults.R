# @file summarizeResults.R
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
#' This function will take the data quality check results and evaluate them against the thresholds determined
#' apriori in the csv files and then write the JSON object referenced by the shiny app.
#' 
#' @param connectionDetails A connectionDetails object for connecting to the CDM database
#' @param cdmDatabaseSchema The CDM schema where the data quality checks were run
#' @param checkResults The data frame with the results of the data quality checks
#' @param cdmSourceName The human-readable name of the CDM instance
#' @param outputFolder The folder where the results should be outputted
#' @param startTime The time the threshold evaluation starts
#' @param tableChecks The name of the R object containing the table checks
#' @param fieldChecks The name of the R object containing the field checks
#' @param conceptChecks The name of the R object containing the concept checks
#' 

.summarizeResults <- function(connectionDetails,
                              cdmDatabaseSchema,
                              checkResults,
                              cdmSourceName,
                              outputFolder,
                              startTime,
                              tableChecks,
                              fieldChecks,
                              conceptChecks) {
  
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))
  
  # capture metadata -----------------------------------------------------------------------
  sql <- SqlRender::render(sql = "select * from @cdmDatabaseSchema.cdm_source;",
                           cdmDatabaseSchema = cdmDatabaseSchema)
  sql <- SqlRender::translate(sql = sql, targetDialect = connectionDetails$dbms)
  cdmSourceData <- DatabaseConnector::querySql(connection = connection, sql = sql)
  
  # prepare output ------------------------------------------------------------------------
  metadata <- cdmSourceData
  
  # evaluate thresholds-------------------------------------------------------------------
  
  checkResults <- .evaluateThresholds(checkResults = checkResults, 
                                      tableChecks = tableChecks, 
                                      fieldChecks = fieldChecks,
                                      conceptChecks = conceptChecks)
  
  countTotal <- nrow(checkResults)
  countThresholdFailed <- nrow(checkResults[checkResults$FAILED == 1 & 
                                              is.na(checkResults$ERROR),])
  countErrorFailed <- nrow(checkResults[!is.na(checkResults$ERROR),])
  countOverallFailed <- nrow(checkResults[checkResults$FAILED == 1,])
  
  countPassed <- countTotal - countOverallFailed
  
  countTotalPlausibility <- nrow(checkResults[checkResults$CATEGORY=='Plausibility',])
  countTotalConformance <- nrow(checkResults[checkResults$CATEGORY=='Conformance',])
  countTotalCompleteness <- nrow(checkResults[checkResults$CATEGORY=='Completeness',])
  
  countFailedPlausibility <- nrow(checkResults[checkResults$CATEGORY=='Plausibility' & 
                                                 checkResults$FAILED == 1,])
  
  countFailedConformance <- nrow(checkResults[checkResults$CATEGORY=='Conformance' &
                                                checkResults$FAILED == 1,])
  
  countFailedCompleteness <- nrow(checkResults[checkResults$CATEGORY=='Completeness' &
                                                 checkResults$FAILED == 1,])
  
  countPassedPlausibility <- countTotalPlausibility - countFailedPlausibility
  countPassedConformance <- countTotalConformance - countFailedConformance
  countPassedCompleteness <- countTotalCompleteness - countFailedCompleteness
  
  overview <- list(
    countTotal = countTotal, 
    countPassed = countPassed, 
    countErrorFailed = countErrorFailed,
    countThresholdFailed = countThresholdFailed,
    countOverallFailed = countOverallFailed,
    percentPassed = round(countPassed / countTotal * 100),
    percentFailed = round(countOverallFailed / countTotal * 100),
    countTotalPlausibility = countTotalPlausibility,
    countTotalConformance = countTotalConformance,
    countTotalCompleteness = countTotalCompleteness,
    countFailedPlausibility = countFailedPlausibility,
    countFailedConformance = countFailedConformance,
    countFailedCompleteness = countFailedCompleteness,
    countPassedPlausibility = countPassedPlausibility,
    countPassedConformance = countPassedConformance,
    countPassedCompleteness = countPassedCompleteness
  )
  
  endTime <- Sys.time()
  delta <- endTime - startTime
  
  result <- list(startTimestamp = startTime, 
                 endTimestamp = endTime,
                 executionTime = sprintf("%.0f %s", delta, attr(delta, "units")),
                 CheckResults = checkResults, 
                 Metadata = metadata, 
                 Overview = overview)
  
  resultJson <- jsonlite::toJSON(result)
  write(resultJson, file.path(outputFolder, sprintf("results_%s.json", cdmSourceName)))
  
  result
}