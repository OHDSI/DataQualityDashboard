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

#' Internal function to define the id of each check.
#'
#' @param checkLevel                The level of the check. Options are table, field, or concept
#' @param checkName                 The name of the data quality check
#' @param cdmTableName              The name of the CDM data table the quality check is applied to
#' @param cdmFieldName              The name of the field in the CDM data table the quality check is applied to
#' @param conceptId                 The concept id the quality check is applied to
#' @param unitConceptId             The unit concept id the quality check is applied to
#'
#' @keywords internal
#' @importFrom stats na.omit
#'

.getCheckId <- function(checkLevel,
                        checkName,
                        cdmTableName,
                        cdmFieldName = NA,
                        conceptId = NA,
                        unitConceptId = NA) {
  tolower(
    paste(
      na.omit(c(
        dplyr::na_if(gsub(" ", "", checkLevel), ""),
        dplyr::na_if(gsub(" ", "", checkName), ""),
        dplyr::na_if(gsub(" ", "", cdmTableName), ""),
        dplyr::na_if(gsub(" ", "", cdmFieldName), ""),
        dplyr::na_if(gsub(" ", "", conceptId), ""),
        dplyr::na_if(gsub(" ", "", unitConceptId), "")
      )),
      collapse = "_"
    )
  )
}
