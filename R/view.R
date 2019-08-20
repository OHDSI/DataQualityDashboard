
#' View DQ Dashboard
#' 
#' @param jsonPath       The path to the JSON file produced by executeDqDashboard
#' 
#' @export
viewDqDashboard <- function(jsonPath) {
  Sys.setenv(jsonPath = jsonPath)
  appDir <- system.file("shinyApps", package = "DataQualityDashboard")
  shiny::runApp(appDir = appDir, display.mode = "normal", launch.browser = TRUE)
}