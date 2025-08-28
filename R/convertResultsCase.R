# Copyright 2025 Observational Health Data Sciences and Informatics
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

#' @title Convert JSON results file case
#'
#' @description Convert a DQD JSON results file between camelcase and (all-caps) snakecase. Enables viewing of pre-v.2.1.0 results files in later DQD versions, and vice versa
#'
#' @param jsonFilePath  Path to the JSON results file to be converted
#' @param writeToFile   Whether or not to write the converted results back to a file (must be either TRUE or FALSE)
#' @param outputFolder  The folder to output the converted JSON results file to
#' @param outputFile    (OPTIONAL) File to write converted results JSON object to. Default is name of input file with a "_camel" or "_snake" postfix
#' @param targetCase    Case into which the results file parameters should be converted (must be either "camel" or "snake")
#'
#' @returns DQD results object (a named list)
#'
#' @importFrom jsonlite fromJSON
#' @importFrom SqlRender snakeCaseToCamelCase camelCaseToSnakeCase
#' @importFrom dplyr rename_with
#' @importFrom tools file_path_sans_ext
#' @importFrom readr local_edition
#'
#' @export

convertJsonResultsFileCase <- function(
    jsonFilePath,
    writeToFile,
    outputFolder = NA,
    outputFile = "",
    targetCase) {
  if (!any(targetCase %in% c("camel", "snake"))) {
    stop("targetCase must be either 'camel' or 'snake'.")
  }
  stopifnot(is.logical(writeToFile))
  if (writeToFile && is.na(outputFolder)) {
    stop("You must specify an output folder if writing to file.")
  }

  # temporary patch to work around vroom 1.6.4 bug
  readr::local_edition(1)

  results <- jsonlite::fromJSON(jsonFilePath)

  if ("numViolatedRows" %in% names(results$CheckResults) && targetCase == "camel") {
    warning("File is already in camelcase! No conversion will be performed.")
    return(results)
  }
  if ("NUM_VIOLATED_ROWS" %in% names(results$CheckResults) && targetCase == "snake") {
    warning("File is already in snakecase! No conversion will be performed.")
    return(results)
  }

  if (targetCase == "camel") {
    swapFunction <- SqlRender::snakeCaseToCamelCase
  } else {
    swapFunction <- function(x) {
      toupper(SqlRender::camelCaseToSnakeCase(x))
    }
  }

  results$Metadata <- dplyr::rename_with(results$Metadata, swapFunction)
  results$CheckResults <- dplyr::rename_with(results$CheckResults, swapFunction, -c("checkId"))

  if (writeToFile) {
    if (nchar(outputFile) == 0) {
      jsonFile <- tools::file_path_sans_ext(basename(jsonFilePath))
      outputFile <- paste(jsonFile, "_", targetCase, ".json", sep = "")
    }
    .writeResultsToJson(results, outputFolder, outputFile)
  }

  return(results)
}
