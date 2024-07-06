# Copyright 2024 Observational Health Data Sciences and Informatics
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
#' @param launch.browser Passed on to \code{shiny::runApp}
#' @param display.mode   Passed on to \code{shiny::runApp}
#' @param ...            Extra parameters for shiny::runApp() like "port" or "host"
#'
#' @importFrom utils menu install.packages
#' @importFrom jsonlite toJSON parse_json
#'
#' @export
viewDqDashboard <- function(jsonPath, launch.browser = NULL, display.mode = NULL, ...) {
  ensure_installed("shiny")

  Sys.setenv(jsonPath = jsonPath)
  appDir <- system.file("shinyApps", package = "DataQualityDashboard")

  if (is.null(display.mode)) {
    display.mode <- "normal"
  }

  if (is.null(launch.browser)) {
    launch.browser <- TRUE
  }

  shiny::runApp(appDir = appDir, launch.browser = launch.browser, display.mode = display.mode, ...)
}


# Borrowed from devtools:
# https://github.com/hadley/devtools/blob/ba7a5a4abd8258c52cb156e7b26bb4bf47a79f0b/R/utils.r#L44
is_installed <- function(pkg, version = "0") {
  installed_version <-
    tryCatch(
      utils::packageVersion(pkg),
      error = function(e) {
        NA
      }
    )
  !is.na(installed_version) && installed_version >= version
}

# Borrowed and adapted from devtools:
# https://github.com/hadley/devtools/blob/ba7a5a4abd8258c52cb156e7b26bb4bf47a79f0b/R/utils.r#L74
ensure_installed <- function(pkg) {
  if (!is_installed(pkg)) {
    msg <-
      paste0(sQuote(pkg), " must be installed for this functionality.")
    if (interactive()) {
      message(msg, "\nWould you like to install it?")
      if (menu(c("Yes", "No")) == 1) {
        install.packages(pkg)
      } else {
        stop(msg, call. = FALSE)
      }
    } else {
      stop(msg, call. = FALSE)
    }
  }
}
