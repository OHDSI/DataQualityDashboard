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


#' @title List DQ checks
#'
#' @description Details on all checks defined by the DataQualityDashboard Package.
#'
#' @param cdmVersion                The CDM version to target for the data source. By default, 5.3 is used.
#' @param tableCheckThresholdLoc    The location of the threshold file for evaluating the table checks. If not specified the default thresholds will be applied.
#' @param fieldCheckThresholdLoc    The location of the threshold file for evaluating the field checks. If not specified the default thresholds will be applied.
#' @param conceptCheckThresholdLoc  The location of the threshold file for evaluating the concept checks. If not specified the default thresholds will be applied.
#'
#' @importFrom readr read_csv local_edition
#'
#' @export
listDqChecks <- function(cdmVersion = "5.3", tableCheckThresholdLoc = "default", fieldCheckThresholdLoc = "default", conceptCheckThresholdLoc = "default") {
  # temporary patch to work around vroom 1.6.4 bug
  readr::local_edition(1)

  dqChecks <- {}
  dqChecks$checkDescriptions <-
    read_csv(system.file(
      "csv",
      sprintf("OMOP_CDMv%s_Check_Descriptions.csv", cdmVersion),
      package = "DataQualityDashboard"
    ))

  dqChecks$tableChecks <- .readThresholdFile(
    checkThresholdLoc = tableCheckThresholdLoc,
    defaultLoc = sprintf("OMOP_CDMv%s_Table_Level.csv", cdmVersion)
  )

  dqChecks$fieldChecks <- .readThresholdFile(
    checkThresholdLoc = fieldCheckThresholdLoc,
    defaultLoc = sprintf("OMOP_CDMv%s_Field_Level.csv", cdmVersion)
  )

  dqChecks$conceptChecks <- .readThresholdFile(
    checkThresholdLoc = conceptCheckThresholdLoc,
    defaultLoc = sprintf("OMOP_CDMv%s_Concept_Level.csv", cdmVersion)
  )

  return(dqChecks)
}
