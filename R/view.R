# @file view.R
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


#' View DQ Dashboard
#' 
#' @param jsonPath       The path to the JSON file produced by  \code{\link{executeDqChecks}}
#' @param ...            Extra parameters for shiny::runApp() like "port" or "host"
#'
#' @export
viewDqDashboard <- function(jsonPath, launch.browser=NULL, display.mode=NULL, ...) {
  Sys.setenv(jsonPath = jsonPath)
  appDir <- system.file("shinyApps", package = "DataQualityDashboard")

  if(is.null(display.mode)){
      display.mode="normal"
  }

  if(is.null(launch.browser)){
      launch.browser=TRUE
  }

  shiny::runApp(appDir = appDir, launch.browser, display.mode, ...)
}
