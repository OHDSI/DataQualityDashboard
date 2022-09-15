
#' Internal function to summarize the results of the DQD run.
#' 
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param cdmDatabaseSchema         The fully qualified database name of the CDM schema
#' @param checkResults              A dataframe containing the results of the checks after running against the database
#' @param cdmSourceName             The name of the CDM data source
#' @param outputFolder              The folder to output logs and SQL files to
#' @param outputFile                (OPTIONAL) File to write results JSON object 
#' @param startTime                 The system time the check was started
#' @param tablechecks               A dataframe containing the table checks
#' @param fieldChecks               A dataframe containing the field checks
#' @param conceptChecks             A dataframe containing the concept checks
#' @param metadata                  Information from the CDM_SOURCE table with details about the database
#' 
#' @keywords internal
#' 

.summarizeResults <- function(connectionDetails,
                              cdmDatabaseSchema,
                              checkResults,
                              cdmSourceName,
                              outputFolder,
                              outputFile,
                              startTime,
                              tableChecks,
                              fieldChecks,
                              conceptChecks,
                              metadata) {
  
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))
  
  # evaluate thresholds-------------------------------------------------------------------
  checkResults <- DataQualityDashboard:::.evaluateThresholds(checkResults = checkResults, 
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
  
  countPassedPlausibility <- nrow(checkResults[checkResults$CATEGORY=='Plausibility' &
                                                 checkResults$PASSED == 1,]) 
  
  countPassedConformance <- nrow(checkResults[checkResults$CATEGORY=='Conformance' &
                                                checkResults$PASSED == 1,]) 
  
  countPassedCompleteness <- nrow(checkResults[checkResults$CATEGORY=='Completeness' &
                                                 checkResults$PASSED == 1,])
  
  overview <- list(
    countTotal = countTotal, 
    countPassed = countPassed, 
    countErrorFailed = countErrorFailed,
    countThresholdFailed = countThresholdFailed,
    countOverallFailed = countOverallFailed,
    percentPassed = round(countPassed / (countPassed + countOverallFailed) * 100, 2),
    percentFailed = round(countOverallFailed / (countPassed + countOverallFailed) * 100, 2),
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
  
  if (nchar(outputFile)==0)  {
    endTimestamp <- format(endTime, "%Y%m%d%H%M%S")
    outputFile <- sprintf("%s-%s.json", tolower(metadata$CDM_SOURCE_ABBREVIATION),endTimestamp)
  }
  
  resultFilename <- file.path(outputFolder,outputFile)
  result$outputFile <- outputFile
  
  ParallelLogger::logInfo(sprintf("Writing results to file: %s", resultFilename))
  write(resultJson, resultFilename)
  
  result
}