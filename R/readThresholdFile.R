.readThresholdFile <- function(checkThresholdLoc, defaultLoc) {
  if (checkThresholdLoc == "default") {
    result <- read.csv(
      file = system.file(
        "csv",
        defaultLoc,
        package = "DataQualityDashboard"
      ), 
      stringsAsFactors = FALSE, 
      na.strings = c(" ","")
    )
  } else {
    result <- read.csv(
      file = checkThresholdLoc, 
      stringsAsFactors = FALSE, 
      na.strings = c(" ","")
    )
  }
  return(result)
}