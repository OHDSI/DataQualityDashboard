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

#' Determines if all checks are present expected to calculate the 'Not Applicable' status
#'
#' @param checkResults A dataframe containing the results of the data quality checks
#'
#' @keywords internal
.hasNAchecks <- function(checkResults) {
  checkNames <- unique(checkResults$checkName)
  return(.containsNAchecks(checkNames))
}

#' Determines if all checks required for 'Not Applicable' status are in the checkNames
#'
#' @param checkNames A character vector of check names
#'
#' @keywords internal
.containsNAchecks <- function(checkNames) {
  naCheckNames <- c("cdmTable", "cdmField", "measureValueCompleteness")
  missingNAChecks <- !(naCheckNames %in% checkNames)
  if (any(missingNAChecks)) {
    return(FALSE)
  }
  return(TRUE)
}

#' Applies the 'Not Applicable' status to a single check
#'
#' @param x Results from a single check
#'
#' @keywords internal
.applyNotApplicable <- function(x) {
  # Errors precede all other statuses
  if (x$isError == 1) {
    return(0)
  }

  # No NA status for cdmTable and cdmField if missing
  if (x$checkName == "cdmTable" || x$checkName == "cdmField") {
    return(0)
  }

  if (any(x$tableIsMissing, x$fieldIsMissing, x$tableIsEmpty, na.rm = TRUE)) {
    return(1)
  }

  # No NA status for measureValueCompleteness if empty
  if (x$checkName == "measureValueCompleteness") {
    return(0)
  }

  if (any(x$fieldIsEmpty, x$conceptIsMissing, x$conceptAndUnitAreMissing, na.rm = TRUE)) {
    return(1)
  }

  return(0)
}

#' Determines if check should be notApplicable and the notApplicableReason
#'
#' @param checkResults A dataframe containing the results of the data quality checks
#'
#' @keywords internal
.calculateNotApplicableStatus <- function(checkResults) {
  # Look up missing tables and add variable tableIsMissing to checkResults
  missingTables <- checkResults %>%
    dplyr::filter(
      .data$checkName == "cdmTable"
    ) %>%
    dplyr::mutate(
      .data$cdmTableName,
      tableIsMissing = .data$failed == 1,
      .keep = "none"
    )

  # Look up missing fields and add variable fieldIsMissing to checkResults
  missingFields <- checkResults %>%
    dplyr::filter(
      .data$checkName == "cdmField"
    ) %>%
    dplyr::mutate(
      .data$cdmTableName,
      .data$cdmFieldName,
      fieldIsMissing = .data$failed == 1,
      .keep = "none"
    )

  # Look up empty tables and add variable tableIsEmpty to checkResults
  emptyTables <- checkResults %>%
    dplyr::filter(
      .data$checkName == "measureValueCompleteness"
    ) %>%
    dplyr::mutate(
      .data$cdmTableName,
      tableIsEmpty = .data$numDenominatorRows == 0,
      .keep = "none"
    ) %>%
    dplyr::distinct()

  # Look up empty fields and add variable fieldIsEmpty to checkResults
  emptyFields <- checkResults %>%
    dplyr::filter(
      .data$checkName == "measureValueCompleteness"
    ) %>%
    dplyr::mutate(
      .data$cdmTableName,
      .data$cdmFieldName,
      fieldIsEmpty = .data$numDenominatorRows == .data$numViolatedRows,
      .keep = "none"
    )

  # Assign notApplicable status
  checkResults <- checkResults %>%
    dplyr::left_join(
      missingTables,
      by = "cdmTableName"
    ) %>%
    dplyr::left_join(
      missingFields,
      by = c("cdmTableName", "cdmFieldName")
    ) %>%
    dplyr::left_join(
      emptyTables,
      by = "cdmTableName"
    ) %>%
    dplyr::left_join(
      emptyFields,
      by = c("cdmTableName", "cdmFieldName")
    ) %>%
    dplyr::mutate(
      conceptIsMissing = .data$checkLevel == "CONCEPT" & is.na(.data$unitConceptId) & .data$numDenominatorRows == 0,
      conceptAndUnitAreMissing = .data$checkLevel == "CONCEPT" & !is.na(.data$unitConceptId) & .data$numDenominatorRows == 0,
      fieldIsMissing = dplyr::coalesce(.data$fieldIsMissing, !is.na(.data$cdmFieldName)),
      fieldIsEmpty = dplyr::coalesce(.data$fieldIsEmpty, !is.na(.data$cdmFieldName)),
    )

  checkResults$notApplicable <- NA
  checkResults$notApplicableReason <- NA

  conditionOccurrenceIsMissing <- missingTables %>%
    dplyr::filter(.data$cdmTableName == "CONDITION_OCCURRENCE") %>%
    dplyr::pull(.data$tableIsMissing)
  conditionOccurrenceIsEmpty <- emptyTables %>%
    dplyr::filter(.data$cdmTableName == "CONDITION_OCCURRENCE") %>%
    dplyr::pull(.data$tableIsEmpty)
  for (i in seq_len(nrow(checkResults))) {
    # Special rule for measureConditionEraCompleteness, which should be notApplicable if CONDITION_OCCURRENCE is empty
    if (checkResults[i, "checkName"] == "measureConditionEraCompleteness") {
      if (conditionOccurrenceIsMissing || conditionOccurrenceIsEmpty) {
        checkResults$notApplicable[i] <- 1
        checkResults$notApplicableReason[i] <- "Table CONDITION_OCCURRENCE is empty."
      } else {
        checkResults$notApplicable[i] <- 0
      }
    } else {
      checkResults$notApplicable[i] <- .applyNotApplicable(checkResults[i, ])
    }
  }

  checkResults <- checkResults %>%
    dplyr::mutate(
      notApplicableReason = ifelse(
        .data$notApplicable == 1,
        dplyr::case_when(
          !is.na(.data$notApplicableReason) ~ .data$notApplicableReason,
          .data$tableIsMissing ~ sprintf("Table %s does not exist.", .data$cdmTableName),
          .data$fieldIsMissing ~ sprintf("Field %s.%s does not exist.", .data$cdmTableName, .data$cdmFieldName),
          .data$tableIsEmpty ~ sprintf("Table %s is empty.", .data$cdmTableName),
          .data$fieldIsEmpty ~ sprintf("Field %s.%s is not populated.", .data$cdmTableName, .data$cdmFieldName),
          .data$conceptIsMissing ~ sprintf("%s=%s is missing from the %s table.", .data$cdmFieldName, .data$conceptId, .data$cdmTableName),
          .data$conceptAndUnitAreMissing ~ sprintf("Combination of %s=%s, unitConceptId=%s and VALUE_AS_NUMBER IS NOT NULL is missing from the %s table.", .data$cdmFieldName, .data$conceptId, .data$unitConceptId, .data$cdmTableName) # nolint
        ),
        NA
      ),
      failed = ifelse(.data$notApplicable == 1, 0, .data$failed),
      passed = ifelse(.data$failed == 0 & .data$isError == 0 & .data$notApplicable == 0, 1, 0)
    ) %>%
    dplyr::select(-c("tableIsMissing", "fieldIsMissing", "tableIsEmpty", "fieldIsEmpty", "conceptIsMissing", "conceptAndUnitAreMissing"))

  return(checkResults)
}
