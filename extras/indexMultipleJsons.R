# @file studyathonEngineering
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

# Potential verbiage for paper introduction:
# The 'DataQualityDashboard' package provides a framework for data quality assessment for data in the OMOP CDM format.
# For the purposes of this study a subset of data quality checks were determined to be critical for data quality assessment.
# The results of those assessments are summarized and the complete results available as an appendix.

#' Index
#'
#' @param inputFolder       Location of all DataQualityDashboard results
#' @param outputFolder      Location to store summary and result files
#'
#' @export

library("dplyr")

subsetDataQualityChecks <- function(inputFolder, outputFolder) {
  overallResults <- data.frame()
  overallChecks <- data.frame()
  
  checkNames <- c("cdmField", "isRequired", "cdmDatatype", "isPrimaryKey", "isForeignKey", "fkDomain", "fkClass", "isStandardValidConcept")
  tables <- c("PERSON", "OBSERVATION_PERIOD", "VISIT_OCCURRENCE", "CONDITION_OCCURRENCE", "DRUG_EXPOSURE", "PROCEDURE_OCCURRENCE", "MEASUREMENT", "OBSERVATION", "DRUG_ERA", "CONDITION_ERA")
  excludedFieldNames <- c("device_exposure_id", "visit_detail_id", "note_id", "specimen_id", "location_id", "care_site_id", "provider_id", "payer_plan_period_id", "dose_era_id", "drug_source_concept_id", "observation_source_concept_id", "condition_source_concept_id", "procedure_source_concept_id", "modifier_source_value", "measurement_time", "route_concept_id")
  
  resultFiles <- list.files(path = inputFolder, full.names = T, pattern = "json")
  for (f in resultFiles) {
    writeLines(paste("processing", f))
    fileContents <- readLines(f, warn = FALSE)
    fileContentsConverted <- iconv(fileContents, 'utf-8', 'utf-8', sub = '')
    resultJson <- rjson::fromJSON(fileContentsConverted,simplify=T)  
    
    # convert results to dataframe    
    checkResults <-resultJson$CheckResults
    checkResultsDf <- lapply(checkResults, function(cr) {
      cr[sapply(cr, is.null)] <- NA
      as.data.frame(cr)
    })
    checkResultsDf <- do.call(plyr::rbind.fill, checkResultsDf)    
    
    # subset results to specified checkNames and tables
    checkResultsSubset <- checkResultsDf %>% filter(CDM_TABLE_NAME %in% tables & CHECK_NAME %in% checkNames & !(CDM_FIELD_NAME %in% excludedFieldNames))
    checkResultsSubsetJson <- rjson::toJSON(unname(split(checkResultsSubset, 1:nrow(checkResultsSubset))))
    resultJson$CheckResults <- unname(split(checkResultsSubset, 1:nrow(checkResultsSubset)))
    
    checkResultsSubsetFailed <- checkResultsSubset %>% filter(FAILED == 1)
    checkResultsSubsetFailedJson <- rjson::toJSON(unname(split(checkResultsSubsetFailed, 1:nrow(checkResultsSubsetFailed))))
    write(checkResultsSubsetFailedJson,file.path(outputFolder,paste0(basename(f),".failed.json")))
    
    countTotal <- nrow(checkResultsSubset)
    countThresholdFailed <- nrow(checkResultsSubset[checkResultsSubset$FAILED == 1 & 
                                                      is.na(checkResultsSubset$ERROR),])
    countErrorFailed <- nrow(checkResultsSubset[!is.na(checkResultsSubset$ERROR),])
    countOverallFailed <- nrow(checkResultsSubset[checkResultsSubset$FAILED == 1,])
    
    countPassed <- countTotal - countOverallFailed
    
    countTotalPlausibility <- nrow(checkResultsSubset[checkResultsSubset$CATEGORY=='Plausibility',])
    countTotalConformance <- nrow(checkResultsSubset[checkResultsSubset$CATEGORY=='Conformance',])
    countTotalCompleteness <- nrow(checkResultsSubset[checkResultsSubset$CATEGORY=='Completeness',])
    
    countFailedPlausibility <- nrow(checkResultsSubset[checkResultsSubset$CATEGORY=='Plausibility' & 
                                                         checkResultsSubset$FAILED == 1,])
    
    countFailedConformance <- nrow(checkResultsSubset[checkResultsSubset$CATEGORY=='Conformance' &
                                                        checkResultsSubset$FAILED == 1,])
    
    countFailedCompleteness <- nrow(checkResultsSubset[checkResultsSubset$CATEGORY=='Completeness' &
                                                         checkResultsSubset$FAILED == 1,])
    
    countPassedPlausibility <- countTotalPlausibility - countFailedPlausibility
    countPassedConformance <- countTotalConformance - countFailedConformance
    countPassedCompleteness <- countTotalCompleteness - countFailedCompleteness
    
    cdmSourceChecks <- checkResultsSubset
    cdmSourceChecks$CDM_SOURCE_NAME <- resultJson$Metadata[[1]]$CDM_SOURCE_NAME
    overallChecks <- dplyr::bind_rows(overallChecks, cdmSourceChecks)
    
    overview <- list(
      cdmSourceName = resultJson$Metadata[[1]]$CDM_SOURCE_NAME,
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
    
    resultJson$Overview <- overview
    write(rjson::toJSON(resultJson),file.path(outputFolder,paste0(basename(f),".subset.json")))
    
    overviewDf <- as.data.frame(overview)
    overallResults <- rbind(overallResults, overviewDf)
  }
  return(list(networkResults = overallResults, networkChecks = overallChecks))
}

networkResults <- subsetDataQualityChecks("D:/Studies/Studyathon","D:/Studies/Studyathon/output")
View(networkResults)

#DataQualityDashboard::viewDqDashboard(file.path(outputFolder, "results_AD_Momentum.json.subset.json"))
#View(test$networkChecks)
#View(test$networkResults)

# applying a > 5% percentage of violating rows 
networkSummary <-networkResults$networkChecks %>% filter(PCT_VIOLATED_ROWS > 0.05) %>% group_by(CHECK_DESCRIPTION) %>% summarise(failed=sum(FAILED))
View(networkSummary)
