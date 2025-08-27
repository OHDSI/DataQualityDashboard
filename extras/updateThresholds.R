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

## Update thresholds and reevaluate external to the initial run

## Read the json file
jsonFilePath <- "C:/Users/mblacke/Desktop/DQD/MDCD/results_IBM_MDCD_(v1327).json"

# jsonFilePath <- "C:/Users/mblacke/Desktop/DQD/CCAE/results_ccae_v992.json"

## Read in jsonData from the path
jsonData <- jsonlite::read_json(jsonFilePath)
checkResults <- lapply(jsonData$CheckResults, function(cr) {
  cr[sapply(cr, is.null)] <- NA
  as.data.frame(cr)
})

## Take the checkResults and make into a dataFrame
df <- do.call(plyr::rbind.fill, checkResults)

## Read in the thresholds

tableChecks <- read.csv("C:/Users/mblacke/OneDrive - JNJ/DQD_Thresholds/MDCD/OMOP_CDMv5.3.1_Table_Level_MDCD.csv", 
                          stringsAsFactors = FALSE, na.strings = c(" ",""))

fieldChecks <- read.csv("C:/Users/mblacke/OneDrive - JNJ/DQD_Thresholds/MDCD/OMOP_CDMv5.3.1_Field_Level_MDCD.csv", 
                          stringsAsFactors = FALSE, na.strings = c(" ",""))

conceptChecks <- read.csv("C:/Users/mblacke/OneDrive - JNJ/DQD_Thresholds/MDCD/OMOP_CDMv5.3.1_Concept_Level_MDCD.csv", 
                        stringsAsFactors = FALSE, na.strings = c(" ",""))

# if (conceptCheckThresholdLoc == "default"){ 
#   conceptChecks <- read.csv(system.file("csv", sprintf("OMOP_CDMv%s_Concept_Level.csv", "5.3.1"),
#                                         package = "DataQualityDashboard"), 
#                             stringsAsFactors = FALSE, na.strings = c(" ",""))} else {conceptChecks <- read.csv(conceptCheckThresholdLoc, 
#                                                                                                                stringsAsFactors = FALSE, na.strings = c(" ",""))}


## Remove the thresholds, failures, and notes from existing results

checks <- subset(df, select = -c(failed, thresholdValue)) #notesValue column should be removed also if it exists

## use the .evaluateThreshold function to add the new thresholds

checkResults <- evaluateThresholds(checkResults = checks,
                                   tableChecks = tableChecks,
                                   fieldChecks = fieldChecks,
                                   conceptChecks = conceptChecks)

## Recalculate totals and regenerate JSON

countTotal <- nrow(checkResults)
countThresholdFailed <- nrow(checkResults[checkResults$failed == 1 & 
                                        is.na(checkResults$error),])
countErrorFailed <- nrow(checkResults[!is.na(checkResults$error),])
countOverallFailed <- nrow(checkResults[checkResults$failed == 1,])

countPassed <- countTotal - countOverallFailed

countTotalPlausibility <- nrow(checkResults[checkResults$category=='Plausibility',])
countTotalConformance <- nrow(checkResults[checkResults$category=='Conformance',])
countTotalCompleteness <- nrow(checkResults[checkResults$category=='Completeness',])

countFailedPlausibility <- nrow(checkResults[checkResults$category=='Plausibility' & 
                                           checkResults$failed == 1,])

countFailedConformance <- nrow(checkResults[checkResults$category=='Conformance' &
                                          checkResults$failed == 1,])

countFailedCompleteness <- nrow(checkResults[checkResults$category=='Completeness' &
                                           checkResults$failed == 1,])

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

result <- list(startTimestamp = jsonData$startTimestamp, 
               endTimestamp = jsonData$endTimestamp,
               executionTime = jsonData$executionTime,
               CheckResults = checkResults, 
               Metadata = jsonData$Metadata, 
               Overview = overview)

resultJson <- jsonlite::toJSON(result)
write(resultJson, "C:/Users/mblacke/Desktop/DQD/MDCD/results_IBM_MDCD_(v1327)_thresholds.json")

DataQualityDashboard::viewDqDashboard("C:/Users/mblacke/Desktop/DQD/MDCD/results_IBM_MDCD_(v1327)_thresholds.json")









evaluateThresholds <- function(checkResults,
                                tableChecks,
                                fieldChecks,
                                conceptChecks) {
  
  checkResults$failed <- 0
  checkResults$thresholdValue <- NA
  checkResults$notesValue <- NA
  
  if("error" %in% colnames(checkResults) == FALSE){
    checkResults$error <- NA
  }
  
  for (i in 1:nrow(checkResults)) {
    thresholdField <- sprintf("%sThreshold", checkResults[i,]$checkName)
    notesField <- sprintf("%sNotes", checkResults[i,]$checkName)
    
    # find if field exists -----------------------------------------------
    thresholdFieldExists <- eval(parse(text = 
                                         sprintf("'%s' %%in%% colnames(%sChecks)", 
                                                 thresholdField, 
                                                 tolower(checkResults[i,]$checkLevel))))
    
    if (!thresholdFieldExists) {
      thresholdValue <- NA
      notesValue <- NA
    } else {
      if (checkResults[i,]$checkLevel == "TABLE") {
        
        thresholdFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                                   thresholdField, checkResults[i,]$cdmTableName)
        notesFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                               notesField, checkResults[i,]$cdmTableName)
        
      } else if (checkResults[i,]$checkLevel == "FIELD") {
        
        thresholdFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                   fieldChecks$cdmFieldName == '%s']",
                                   thresholdField, 
                                   checkResults[i,]$cdmTableName,
                                   checkResults[i,]$cdmFieldName)
        notesFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                               fieldChecks$cdmFieldName == '%s']",
                               notesField, 
                               checkResults[i,]$cdmTableName,
                               checkResults[i,]$cdmFieldName)
        
        
      } else if (checkResults[i,]$checkLevel == "CONCEPT") {
        
        if (is.na(checkResults[i,]$unitConceptId)) {
          
          thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                     conceptChecks$cdmFieldName == '%s' &
                                     conceptChecks$conceptId == %s]",
                                     thresholdField, 
                                     checkResults[i,]$cdmTableName,
                                     checkResults[i,]$cdmFieldName,
                                     checkResults[i,]$conceptId)
          notesFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                 conceptChecks$cdmFieldName == '%s' &
                                 conceptChecks$conceptId == %s]",
                                 notesField, 
                                 checkResults[i,]$cdmTableName,
                                 checkResults[i,]$cdmFieldName,
                                 checkResults[i,]$conceptId)
        } else {
          
          thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                     conceptChecks$cdmFieldName == '%s' &
                                     conceptChecks$conceptId == %s &
                                     conceptChecks$unitConceptId == '%s']",
                                     thresholdField, 
                                     checkResults[i,]$cdmTableName,
                                     checkResults[i,]$cdmFieldName,
                                     checkResults[i,]$conceptId,
                                     checkResults[i,]$unitConceptId)
          notesFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
                                 notesField, 
                                 checkResults[i,]$cdmTableName,
                                 checkResults[i,]$cdmFieldName,
                                 checkResults[i,]$conceptId,
                                 checkResults[i,]$unitConceptId)
        } 
      }
      
      thresholdValue <- eval(parse(text = thresholdFilter))
      notesValue <- eval(parse(text = notesFilter))
      
      checkResults[i,]$thresholdValue <- thresholdValue
      checkResults[i,]$notesValue <- notesValue
    }
    
    if (!is.na(checkResults[i,]$error)) {
      checkResults[i,]$failed <- 1
    } else if (is.na(thresholdValue)) {
      if (!is.na(checkResults[i,]$numViolatedRows) & checkResults[i,]$numViolatedRows > 0) {
        checkResults[i,]$failed <- 1
      }
    } else if (checkResults[i,]$pctViolatedRows * 100 > thresholdValue) {
      checkResults[i,]$failed <- 1  
    }  
  }
  
  checkResults
}
                 
