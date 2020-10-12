## Write JSON results to dataframe and do some manipulation and rewrite back to JSON
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
    filter(NUM_DENOMINATOR_ROWS != 0)

## fix the cdmField checks where the DQD was calculating them wrong
dfNonZero <- sqldf('SELECT CASE WHEN CHECK_NAME = "cdmField" THEN 0 else NUM_VIOLATED_ROWS end as NUM_VIOLATED_ROWS,
                  CASE WHEN CHECK_NAME = "cdmField" THEN 0 else PCT_VIOLATED_ROWS end as PCT_VIOLATED_ROWS,
                  NUM_DENOMINATOR_ROWS,
                  EXECUTION_TIME,
                  QUERY_TEXT,
                  CHECK_NAME,
                  CHECK_LEVEL,
                  CHECK_DESCRIPTION,
                  CDM_TABLE_NAME,
                  SQL_FILE,
                  CATEGORY,
                  SUBCATEGORY,
                  CONTEXT,
                  checkId,
                  CASE WHEN CHECK_NAME = \'cdmField\' THEN 0 else FAILED end as FAILED,
                  THRESHOLD_VALUE,
                  CDM_FIELD_NAME,
                  ERROR,
                  CONCEPT_ID,
                  UNIT_CONCEPT_ID
                 FROM dfNonZero d')

countTotal <- nrow(dfNonZero)
countThresholdFailed <- nrow(dfNonZero[dfNonZero$FAILED == 1 & 
                                            is.na(dfNonZero$ERROR),])
countErrorFailed <- nrow(dfNonZero[!is.na(dfNonZero$ERROR),])
countOverallFailed <- nrow(dfNonZero[dfNonZero$FAILED == 1,])

countPassed <- countTotal - countOverallFailed

countTotalPlausibility <- nrow(dfNonZero[dfNonZero$CATEGORY=='Plausibility',])
countTotalConformance <- nrow(dfNonZero[dfNonZero$CATEGORY=='Conformance',])
countTotalCompleteness <- nrow(dfNonZero[dfNonZero$CATEGORY=='Completeness',])

countFailedPlausibility <- nrow(dfNonZero[dfNonZero$CATEGORY=='Plausibility' & 
                                               dfNonZero$FAILED == 1,])

countFailedConformance <- nrow(dfNonZero[dfNonZero$CATEGORY=='Conformance' &
                                              dfNonZero$FAILED == 1,])

countFailedCompleteness <- nrow(dfNonZero[dfNonZero$CATEGORY=='Completeness' &
                                               dfNonZero$FAILED == 1,])

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
