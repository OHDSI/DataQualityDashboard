#' Details on all checks defined by the DataQualityDashboard Package.
#' 
#' @param cdmVersion                The CDM version to target for the data source. By default, 5.3.1 is used.
#' @param tableCheckThresholdLoc    The location of the threshold file for evaluating the table checks. If not specified the default thresholds will be applied.
#' @param fieldCheckThresholdLoc    The location of the threshold file for evaluating the field checks. If not specified the default thresholds will be applied.
#' @param conceptCheckThresholdLoc  The location of the threshold file for evaluating the concept checks. If not specified the default thresholds will be applied.
#'
#' @export
listDqChecks <- function(cdmVersion = "5.3.1", tableCheckThresholdLoc = "default", fieldCheckThresholdLoc = "default",conceptCheckThresholdLoc = "default") {
  dqChecks <- {}
  dqChecks$checkDescriptions <-
    read.csv(system.file(
      "csv",
      sprintf("OMOP_CDMv%s_Check_Descriptions.csv", cdmVersion),
      package = "DataQualityDashboard"
    ),
    stringsAsFactors = FALSE)
  
  
  if (tableCheckThresholdLoc == "default") {
    dqChecks$tableChecks <-
      read.csv(
        system.file(
          "csv",
          sprintf("OMOP_CDMv%s_Table_Level.csv", cdmVersion),
          package = "DataQualityDashboard"
        ),
        stringsAsFactors = FALSE,
        na.strings = c(" ", "")
      )
  } else {
    dqChecks$tableChecks <- read.csv(
      tableCheckThresholdLoc,
      stringsAsFactors = FALSE,
      na.strings = c(" ", "")
    )
  }
  
  if (fieldCheckThresholdLoc == "default") {
    dqChecks$fieldChecks <-
      read.csv(
        system.file(
          "csv",
          sprintf("OMOP_CDMv%s_Field_Level.csv", cdmVersion),
          package = "DataQualityDashboard"
        ),
        stringsAsFactors = FALSE,
        na.strings = c(" ", "")
      )
  } else {
    dqChecks$fieldChecks <- read.csv(
      fieldCheckThresholdLoc,
      stringsAsFactors = FALSE,
      na.strings = c(" ", "")
    )
  }
  
  if (conceptCheckThresholdLoc == "default") {
    dqChecks$conceptChecks <-
      read.csv(
        system.file(
          "csv",
          sprintf("OMOP_CDMv%s_Concept_Level.csv", cdmVersion),
          package = "DataQualityDashboard"
        ),
        stringsAsFactors = FALSE,
        na.strings = c(" ", "")
      )
  } else {
    dqChecks$conceptChecks <- read.csv(
      conceptCheckThresholdLoc,
      stringsAsFactors = FALSE,
      na.strings = c(" ", "")
    )
  }
  
  return(dqChecks)
}