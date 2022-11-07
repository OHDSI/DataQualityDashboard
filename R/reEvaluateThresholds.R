# @file reEvaluateThresholds.R
#
# Copyright 2020 Observational Health Data Sciences and Informatics
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

#' @title Re-evaluate Thresholds
#' 
#' @description Re-evaluate an existing DQD result against an updated thresholds file.
#' 
#' @param jsonFilePath              Path to the JSON results file generated using the execute function
#' @param outputFolder              The folder to output new JSON result file to
#' @param outputFile                File to write results JSON object to
#' @param tableCheckThresholdLoc    The location of the threshold file for evaluating the table checks. If not specified the default thresholds will be applied.
#' @param fieldCheckThresholdLoc    The location of the threshold file for evaluating the field checks. If not specified the default thresholds will be applied.
#' @param conceptCheckThresholdLoc  The location of the threshold file for evaluating the concept checks. If not specified the default thresholds will be applied.
#' @param cdmVersion                The CDM version to target for the data source. By default, 5.3 is used.
#' @param systemFileNamespace       The name of the package where the check are stored. If not specified the default `DataQualityDashboard` namespace will be applied.
#'  
#' @export
 
reEvaluateThresholds <- function(jsonFilePath,
                                 outputFolder,
                                 outputFile,
                                 tableCheckThresholdLoc = "default",
                                 fieldCheckThresholdLoc = "default",
                                 conceptCheckThresholdLoc = "default",
                                 cdmVersion = '5.3',
                                 systemFileNamespace = "DataQualityDashboard") {
  # Read in results to data frame --------------------------------------
  dqdResults <- jsonlite::read_json(path = jsonFilePath)
  
  df <- lapply(dqdResults$CheckResults, function(cr) {
    cr[sapply(cr, is.null)] <- NA
    as.data.frame(cr)
  })
  df <- do.call(plyr::rbind.fill, df)

  # Read in  new thresholds ----------------------------------------------
  tableChecks <- .readThresholdFile(tableCheckThresholdLoc, defaultLoc = sprintf("OMOP_CDMv%s_Table_Level.csv", cdmVersion), systemFileNamespace)
  fieldChecks <- .readThresholdFile(fieldCheckThresholdLoc, defaultLoc = sprintf("OMOP_CDMv%s_Field_Level.csv", cdmVersion), systemFileNamespace)
  fieldChecks$cdmFieldName <- toupper(fieldChecks$cdmFieldName) # Uppercase in results, lowercase in threshold files
  conceptChecks <-  .readThresholdFile(conceptCheckThresholdLoc, defaultLoc = sprintf("OMOP_CDMv%s_Concept_Level.csv", cdmVersion), systemFileNamespace)
  conceptChecks$cdmFieldName <- toupper(conceptChecks$cdmFieldName)
  
  newCheckResults <- .evaluateThresholds(df, tableChecks, fieldChecks, conceptChecks)
  
  newOverview <- .summarizeResults(newCheckResults)
  
  newDqdResults <- dqdResults
  newDqdResults$CheckResults <- newCheckResults
  newDqdResults$Overview <- newOverview
  
  .writeResultsToJson(newDqdResults, outputFolder, outputFile)
  
  return(newDqdResults)
}
