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

checks <- subset(df, select = -c(FAILED, THRESHOLD_VALUE)) #NOTES_VALUE column should be removed also if it exists

## use the .evaluateThreshold function to add the new thresholds

checkResults <- evaluateThresholds(checkResults = checks,
                                   tableChecks = tableChecks,
                                   fieldChecks = fieldChecks,
                                   conceptChecks = conceptChecks)

## Recalculate totals and regenerate JSON

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
  
  checkResults$FAILED <- 0
  checkResults$THRESHOLD_VALUE <- NA
  checkResults$NOTES_VALUE <- NA
  
  if("ERROR" %in% colnames(checkResults) == FALSE){
    checkResults$ERROR <- NA
  }
  
  for (i in 1:nrow(checkResults)) {
    thresholdField <- sprintf("%sThreshold", checkResults[i,]$CHECK_NAME)
    notesField <- sprintf("%sNotes", checkResults[i,]$CHECK_NAME)
    
    # find if field exists -----------------------------------------------
    thresholdFieldExists <- eval(parse(text = 
                                         sprintf("'%s' %%in%% colnames(%sChecks)", 
                                                 thresholdField, 
                                                 tolower(checkResults[i,]$CHECK_LEVEL))))
    
    if (!thresholdFieldExists) {
      thresholdValue <- NA
      notesValue <- NA
    } else {
      if (checkResults[i,]$CHECK_LEVEL == "TABLE") {
        
        thresholdFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                                   thresholdField, checkResults[i,]$CDM_TABLE_NAME)
        notesFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                               notesField, checkResults[i,]$CDM_TABLE_NAME)
        
      } else if (checkResults[i,]$CHECK_LEVEL == "FIELD") {
        
        thresholdFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                   fieldChecks$cdmFieldName == '%s']",
                                   thresholdField, 
                                   checkResults[i,]$CDM_TABLE_NAME,
                                   checkResults[i,]$CDM_FIELD_NAME)
        notesFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                               fieldChecks$cdmFieldName == '%s']",
                               notesField, 
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
          notesFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                 conceptChecks$cdmFieldName == '%s' &
                                 conceptChecks$conceptId == %s]",
                                 notesField, 
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
          notesFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
                                 notesField, 
                                 checkResults[i,]$CDM_TABLE_NAME,
                                 checkResults[i,]$CDM_FIELD_NAME,
                                 checkResults[i,]$CONCEPT_ID,
                                 checkResults[i,]$UNIT_CONCEPT_ID)
        } 
      }
      
      thresholdValue <- eval(parse(text = thresholdFilter))
      notesValue <- eval(parse(text = notesFilter))
      
      checkResults[i,]$THRESHOLD_VALUE <- thresholdValue
      checkResults[i,]$NOTES_VALUE <- notesValue
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
                 