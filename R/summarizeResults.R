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

#' Internal function to summarize the results of the DQD run.
#'
#' @param checkResults              A dataframe containing the results of the checks after running against the database
#'
#' @keywords internal
#'

.summarizeResults <- function(checkResults) {
  countTotal <- nrow(checkResults)

  countThresholdFailed <- nrow(checkResults[checkResults$FAILED == 1 &
    is.na(checkResults$ERROR), ])

  countErrorFailed <- nrow(checkResults[!is.na(checkResults$ERROR), ])

  countOverallFailed <- nrow(checkResults[checkResults$FAILED == 1, ])

  countPassed <- countTotal - countOverallFailed

  countTotalPlausibility <- nrow(checkResults[checkResults$CATEGORY == "Plausibility", ])

  countTotalConformance <- nrow(checkResults[checkResults$CATEGORY == "Conformance", ])

  countTotalCompleteness <- nrow(checkResults[checkResults$CATEGORY == "Completeness", ])

  countFailedPlausibility <- nrow(checkResults[checkResults$CATEGORY == "Plausibility" &
    checkResults$FAILED == 1, ])

  countFailedConformance <- nrow(checkResults[checkResults$CATEGORY == "Conformance" &
    checkResults$FAILED == 1, ])

  countFailedCompleteness <- nrow(checkResults[checkResults$CATEGORY == "Completeness" &
    checkResults$FAILED == 1, ])

  countPassedPlausibility <- nrow(checkResults[checkResults$CATEGORY == "Plausibility" &
    checkResults$PASSED == 1, ])

  countPassedConformance <- nrow(checkResults[checkResults$CATEGORY == "Conformance" &
    checkResults$PASSED == 1, ])

  countPassedCompleteness <- nrow(checkResults[checkResults$CATEGORY == "Completeness" &
    checkResults$PASSED == 1, ])

  list(
    countTotal = countTotal,
    countPassed = countPassed,
    countErrorFailed = countErrorFailed,
    countThresholdFailed = countThresholdFailed,
    countOverallFailed = countOverallFailed,
    percentPassed = round(countPassed / (countPassed + countOverallFailed) * 100, 2),
    percentFailed = round(countOverallFailed / (countPassed + countOverallFailed) * 100, 2),
    countTotalPlausibility = countTotalPlausibility,
    countTotalConformance = countTotalConformance,
    countTotalCompleteness = countTotalCompleteness,
    countFailedPlausibility = countFailedPlausibility,
    countFailedConformance = countFailedConformance,
    countFailedCompleteness = countFailedCompleteness,
    countPassedPlausibility = countPassedPlausibility,
    countPassedConformance = countPassedConformance,
    countPassedCompleteness = countPassedCompleteness
  )
}
