# @file listChecks.R
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


#' @title List DQ checks
#' 
#' @description Details on all checks defined by the DataQualityDashboard Package.
#' 
#' @param cdmVersion                The CDM version to target for the data source. By default, 5.3 is used.
#' @param tableCheckThresholdLoc    The location of the threshold file for evaluating the table checks. If not specified the default thresholds will be applied.
#' @param fieldCheckThresholdLoc    The location of the threshold file for evaluating the field checks. If not specified the default thresholds will be applied.
#' @param conceptCheckThresholdLoc  The location of the threshold file for evaluating the concept checks. If not specified the default thresholds will be applied.
#' @param systemFileNamespace       The name of the package where the check are stored. If not specified the default `DataQualityDashboard` namespace will be applied.
#' 
#' @export
listDqChecks <- function(cdmVersion = "5.3", tableCheckThresholdLoc = "default", fieldCheckThresholdLoc = "default",conceptCheckThresholdLoc = "default", systemFileNamespace = "DataQualityDashboard") {
  dqChecks <- {}
  dqChecks$checkDescriptions <-
    read.csv(system.file(
      "csv",
      sprintf("OMOP_CDMv%s_Check_Descriptions.csv", cdmVersion),
      package = systemFileNamespace
    ),
    stringsAsFactors = FALSE)
  
  
  if (tableCheckThresholdLoc == "default") {
    dqChecks$tableChecks <-
      read.csv(
        system.file(
          "csv",
          sprintf("OMOP_CDMv%s_Table_Level.csv", cdmVersion),
          package = systemFileNamespace
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
          package = systemFileNamespace
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
          package = systemFileNamespace
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