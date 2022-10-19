# Copyright 2022 Observational Health Data Sciences and Informatics
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

#' Internal function to get file path of intermediate check results
#'
#' @param outputFolder  The folder to output logs and SQL files to
#' @param checkLevel    The level of the check. Options are table, field, or concept
#' @param checkName     The name of the data quality check
#'
#' @keywords internal

.getCheckResultsFilePath <- function(outputFolder,
                                     checkLevel,
                                     checkName) {
  file.path(outputFolder,
            sprintf("check-result-%s-%s.csv", checkLevel, checkName))
}