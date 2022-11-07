.readThresholdFile <- function(checkThresholdLoc, defaultLoc, systemFileNamespace = "DataQualityDashboard") {
  if (checkThresholdLoc == "default") {
    result <- read.csv(
      file = system.file(
        "csv",
        defaultLoc,
        package = systemFileNamespace
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