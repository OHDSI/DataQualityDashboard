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
# Write JSON results to dataframe and do some manipulation and rewrite back to JSON

library(dplyr)
library(sqldf)

jsonFilePath <- "S:/Git/GitHub/DataQualityDashboard/results/SIDIAP/results_SIDIAP_OHDSI_CDM_V5.3_Database 20v2.json" 

jsonData <- jsonlite::read_json(jsonFilePath)
checkResults <- lapply(jsonData$CheckResults, function(cr) {
  cr[sapply(cr, is.null)] <- NA
  as.data.frame(cr)
})

df <- do.call(plyr::rbind.fill, checkResults)

## Remove records with a zero denominator
dfNonZero <- df %>% 
    filter(numDenominatorRows != 0)

## fix the cdmField checks where the DQD was calculating them wrong
dfNonZero <- sqldf('SELECT CASE WHEN checkName = "cdmField" THEN 0 else numViolatedRows end as numViolatedRows,
                  CASE WHEN checkName = "cdmField" THEN 0 else pctViolatedRows end as pctViolatedRows,
                  numDenominatorRows,
                  executionTime,
                  queryText,
                  checkName,
                  checkLevel,
                  checkDescription,
                  cdmTableName,
                  sqlFile,
                  category,
                  subcategory,
                  context,
                  checkId,
                  CASE WHEN checkName = \'cdmField\' THEN 0 else failed end as failed,
                  thresholdValue,
                  cdmFieldName,
                  error,
                  conceptId,
                  unitConceptId
                 FROM dfNonZero d')

countTotal <- nrow(dfNonZero)
countThresholdFailed <- nrow(dfNonZero[dfNonZero$failed == 1 & 
                                            is.na(dfNonZero$error),])
countErrorFailed <- nrow(dfNonZero[!is.na(dfNonZero$error),])
countOverallFailed <- nrow(dfNonZero[dfNonZero$failed == 1,])

countPassed <- countTotal - countOverallFailed

countTotalPlausibility <- nrow(dfNonZero[dfNonZero$category=='Plausibility',])
countTotalConformance <- nrow(dfNonZero[dfNonZero$category=='Conformance',])
countTotalCompleteness <- nrow(dfNonZero[dfNonZero$category=='Completeness',])

countFailedPlausibility <- nrow(dfNonZero[dfNonZero$category=='Plausibility' & 
                                               dfNonZero$failed == 1,])

countFailedConformance <- nrow(dfNonZero[dfNonZero$category=='Conformance' &
                                              dfNonZero$failed == 1,])

countFailedCompleteness <- nrow(dfNonZero[dfNonZero$category=='Completeness' &
                                               dfNonZero$failed == 1,])

countPassedPlausibility <- countTotalPlausibility - countFailedPlausibility
countPassedConformance <- countTotalConformance - countFailedConformance
countPassedCompleteness <- countTotalCompleteness - countFailedCompleteness

overview <- list(
  countTotal = as.list(countTotal), 
  countPassed = as.list(countPassed), 
  countErrorFailed = as.list(countErrorFailed),
  countThresholdFailed = as.list(countThresholdFailed),
  countOverallFailed = as.list(countOverallFailed),
  percentPassed = as.list(round(countPassed / countTotal * 100)),
  percentFailed = as.list(round(countOverallFailed / countTotal * 100)),
  countTotalPlausibility = as.list(countTotalPlausibility),
  countTotalConformance = as.list(countTotalConformance),
  countTotalCompleteness = as.list(countTotalCompleteness),
  countFailedPlausibility = as.list(countFailedPlausibility),
  countFailedConformance = as.list(countFailedConformance),
  countFailedCompleteness = as.list(countFailedCompleteness),
  countPassedPlausibility = as.list(countPassedPlausibility),
  countPassedConformance = as.list(countPassedConformance),
  countPassedCompleteness = as.list(countPassedCompleteness)
)


result <- list(startTimestamp = jsonData[["startTimestamp"]], 
               endTimestamp = jsonData[["endTimestamp"]],
               executionTime = jsonData[["executionTime"]],
               CheckResults = dfNonZero, 
               Metadata = jsonData[["Metadata"]], 
               Overview = overview)

resultJson <- jsonlite::toJSON(result)



write(resultJson, "S:/Git/GitHub/DataQualityDashboard/results/SIDIAP/results_SIDIAP_OHDSI_CDM_V5.3_Database_20v2_fix.json" )
