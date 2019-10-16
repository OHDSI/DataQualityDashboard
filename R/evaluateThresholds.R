# @file evaluateThresholds.R
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
#' apriori in the csv files
#' 
#' @param checkResults The data frame with the results of the data quality checks
#' @param tableChecks The name of the R object containing the table checks
#' @param fieldChecks The name of the R object containing the field checks
#' @param conceptChecks The name of the R object containing the concept checks
#' 


.evaluateThresholds <- function(checkResults,
                                tableChecks,
                                fieldChecks,
                                conceptChecks) {
  
  checkResults$FAILED <- 0
  checkResults$THRESHOLD_VALUE <- NA
  
  for (i in 1:nrow(checkResults)) {
    thresholdField <- sprintf("%sThreshold", checkResults[i,]$CHECK_NAME)
    
    # find if field exists -----------------------------------------------
    thresholdFieldExists <- eval(parse(text = 
                                         sprintf("'%s' %%in%% colnames(%sChecks)", 
                                                 thresholdField, 
                                                 tolower(checkResults[i,]$CHECK_LEVEL))))
    
    if (!thresholdFieldExists) {
      thresholdValue <- NA
    } else {
      if (checkResults[i,]$CHECK_LEVEL == "TABLE") {
        
        thresholdFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                                   thresholdField, checkResults[i,]$CDM_TABLE_NAME)
        
      } else if (checkResults[i,]$CHECK_LEVEL == "FIELD") {
        
        thresholdFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
                                   thresholdField, 
                                   checkResults[i,]$CDM_TABLE_NAME,
                                   checkResults[i,]$CDM_FIELD_NAME)
        
        
      } else if (checkResults[i,]$CHECK_LEVEL == "CONCEPT") {
        
        if (is.na(checkResults[i,]$UNIT_CONCEPT_ID)) {
          
          thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s]",
                                     thresholdField, 
                                     checkResults[i,]$CDM_TABLE_NAME,
                                     checkResults[i,]$CDM_FIELD_NAME,
                                     checkResults[i,]$CONCEPT_ID)
        } else {
          
          thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
                                     thresholdField, 
                                     checkResults[i,]$CDM_TABLE_NAME,
                                     checkResults[i,]$CDM_FIELD_NAME,
                                     checkResults[i,]$CONCEPT_ID,
                                     checkResults[i,]$UNIT_CONCEPT_ID)
        } 
      }
      
      thresholdValue <- eval(parse(text = thresholdFilter))
      checkResults[i,]$THRESHOLD_VALUE <- thresholdValue
    }
    
    if (!is.na(checkResults[i,]$ERROR)) {
      checkResults[i,]$FAILED <- 1
    } else if (is.na(thresholdValue)) {
      if (!is.na(checkResults[i,]$NUM_VIOLATED_ROWS) & checkResults[i,]$NUM_VIOLATED_ROWS > 0) {
        checkResults[i,]$FAILED <- 1
      }
    } else if (checkResults[i,]$PCT_VIOLATED_ROWS * 100 > thresholdValue) {
      checkResults[i,]$FAILED <- 1  
    }  
  }
  
  checkResults
}
