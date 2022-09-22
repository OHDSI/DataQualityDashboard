#' Re-evaluate an existing DQD result against an updated thresholds file.
#' 
#' @param jsonFilePath              Path to the JSON results file generated using the execute function
#' @param outputFolder              The folder to output new JSON result file to
#' @param outputFile                File to write results JSON object to
#' @param tableCheckThresholdLoc    The location of the threshold file for evaluating the table checks. If not specified the default thresholds will be applied.
#' @param fieldCheckThresholdLoc    The location of the threshold file for evaluating the field checks. If not specified the default thresholds will be applied.
#' @param conceptCheckThresholdLoc  The location of the threshold file for evaluating the concept checks. If not specified the default thresholds will be applied.
#' @param cdmVersion                The CDM version to target for the data source. By default, 5.3.1 is used.
#' 
#' @export
 
reEvaluateThresholds <- function(jsonFilePath,
                                 outputFolder,
                                 outputFile,
                                 tableCheckThresholdLoc = "default",
                                 fieldCheckThresholdLoc = "default",
                                 conceptCheckThresholdLoc = "default",
                                 cdmVersion = '5.3.1') {
  # Read in results to data frame --------------------------------------
  dqdResults <- jsonlite::read_json(path = jsonFilePath)
  
  df <- lapply(dqdResults$CheckResults, function(cr) {
    cr[sapply(cr, is.null)] <- NA
    as.data.frame(cr)
  })
  df <- do.call(plyr::rbind.fill, df)

  # Read in  new thresholds ----------------------------------------------
  tableChecks <- .readThresholdFile(tableCheckThresholdLoc)
  fieldChecks <- .readThresholdFile(fieldCheckThresholdLoc)
  fieldChecks$cdmFieldName <- toupper(fieldChecks$cdmFieldName) # Uppercase in results, lowercase in threshold files
  conceptChecks <-  .readThresholdFile(conceptCheckThresholdLoc)
  
  newCheckResults <- .evaluateThresholds(df, tableChecks, fieldChecks, conceptChecks)
  
  newOverview <- .summarizeResults(newCheckResults)
  
  newDqdResults <- dqdResults
  newDqdResults$CheckResults <- newCheckResults
  newDqdResults$Overview <- newOverview
  
  .writeResultsToJson(newDqdResults, outputFolder, outputFile)
}
