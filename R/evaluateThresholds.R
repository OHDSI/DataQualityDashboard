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

#' Internal function to evaluate the data quality checks against given thresholds.
#'
#' @param checkResults              A dataframe containing the results of the data quality checks
#' @param tableChecks               A dataframe containing the table checks
#' @param fieldChecks               A dataframe containing the field checks
#' @param conceptChecks             A dataframe containing the concept checks
#'
#' @keywords internal

.evaluateThresholds <- function(checkResults,
                                tableChecks,
                                fieldChecks,
                                conceptChecks) {
  checkResults$failed <- 0
  checkResults$passed <- 0
  checkResults$isError <- 0
  checkResults$notApplicable <- 0
  checkResults$notApplicableReason <- NA
  checkResults$thresholdValue <- NA
  checkResults$notesValue <- NA

  for (i in 1:nrow(checkResults)) {
    thresholdField <- sprintf("%sThreshold", checkResults[i, ]$checkName)
    notesField <- sprintf("%sNotes", checkResults[i, ]$checkName)

    # find if field exists -----------------------------------------------
    thresholdFieldExists <- eval(parse(
      text =
        sprintf(
          "'%s' %%in%% colnames(%sChecks)",
          thresholdField,
          tolower(checkResults[i, ]$checkLevel)
        )
    ))

    if (!thresholdFieldExists) {
      thresholdValue <- NA
      notesValue <- NA
    } else {
      if (checkResults[i, ]$checkLevel == "TABLE") {
        thresholdFilter <- sprintf(
          "tableChecks$%s[tableChecks$cdmTableName == '%s']",
          thresholdField, checkResults[i, ]$cdmTableName
        )
        notesFilter <- sprintf(
          "tableChecks$%s[tableChecks$cdmTableName == '%s']",
          notesField, checkResults[i, ]$cdmTableName
        )
      } else if (checkResults[i, ]$checkLevel == "FIELD") {
        thresholdFilter <- sprintf(
          "fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
          thresholdField,
          checkResults[i, ]$cdmTableName,
          checkResults[i, ]$cdmFieldName
        )
        notesFilter <- sprintf(
          "fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
          notesField,
          checkResults[i, ]$cdmTableName,
          checkResults[i, ]$cdmFieldName
        )
      } else if (checkResults[i, ]$checkLevel == "CONCEPT") {
        if (is.na(checkResults[i, ]$unitConceptId) &&
          grepl(",", checkResults[i, ]$conceptId)) {
          thresholdFilter <- sprintf(
            "conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == '%s']",
            thresholdField,
            checkResults[i, ]$cdmTableName,
            checkResults[i, ]$cdmFieldName,
            checkResults[i, ]$conceptId
          )
          notesFilter <- sprintf(
            "conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == '%s']",
            notesField,
            checkResults[i, ]$cdmTableName,
            checkResults[i, ]$cdmFieldName,
            checkResults[i, ]$conceptId
          )
        } else if (is.na(checkResults[i, ]$unitConceptId) &&
          !grepl(",", checkResults[i, ]$conceptId)) {
          thresholdFilter <- sprintf(
            "conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s]",
            thresholdField,
            checkResults[i, ]$cdmTableName,
            checkResults[i, ]$cdmFieldName,
            checkResults[i, ]$conceptId
          )
          notesFilter <- sprintf(
            "conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s]",
            notesField,
            checkResults[i, ]$cdmTableName,
            checkResults[i, ]$cdmFieldName,
            checkResults[i, ]$conceptId
          )
        } else {
          thresholdFilter <- sprintf(
            "conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
            thresholdField,
            checkResults[i, ]$cdmTableName,
            checkResults[i, ]$cdmFieldName,
            checkResults[i, ]$conceptId,
            as.integer(checkResults[i, ]$unitConceptId)
          )
          notesFilter <- sprintf(
            "conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
            notesField,
            checkResults[i, ]$cdmTableName,
            checkResults[i, ]$cdmFieldName,
            checkResults[i, ]$conceptId,
            as.integer(checkResults[i, ]$unitConceptId)
          )
        }
      }

      thresholdValue <- eval(parse(text = thresholdFilter))
      notesValue <- eval(parse(text = notesFilter))

      checkResults[i, ]$thresholdValue <- thresholdValue
      checkResults[i, ]$notesValue <- notesValue
    }

    if (!is.na(checkResults[i, ]$error)) {
      checkResults[i, ]$isError <- 1
    } else if (is.na(thresholdValue) | thresholdValue == 0) {
      # If no threshold, or threshold is 0%, then any violating records will cause this check to fail
      if (!is.na(checkResults[i, ]$numViolatedRows) & checkResults[i, ]$numViolatedRows > 0) {
        checkResults[i, ]$failed <- 1
      }
    } else if (checkResults[i, ]$pctViolatedRows * 100 > thresholdValue) {
      checkResults[i, ]$failed <- 1
    }
  }

  missingTables <- dplyr::select(
    dplyr::filter(checkResults, .data$checkName == "cdmTable" & .data$failed == 1),
    "cdmTableName"
  )
  if (nrow(missingTables) > 0) {
    missingTables$tableIsMissing <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, missingTables, by = "cdmTableName"),
      tableIsMissing = ifelse(.data$checkName != "cdmTable" & .data$isError == 0, .data$tableIsMissing, NA)
    )
  } else {
    checkResults$tableIsMissing <- NA
  }

  missingFields <- dplyr::select(
    dplyr::filter(checkResults, .data$checkName == "cdmField" & .data$failed == 1 & is.na(.data$tableIsMissing)),
    "cdmTableName", "cdmFieldName"
  )
  if (nrow(missingFields) > 0) {
    missingFields$fieldIsMissing <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, missingFields, by = c("cdmTableName", "cdmFieldName")),
      fieldIsMissing = ifelse(.data$checkName != "cdmField" & .data$isError == 0, .data$fieldIsMissing, NA)
    )
  } else {
    checkResults$fieldIsMissing <- NA
  }

  emptyTables <- dplyr::distinct(
    dplyr::select(
      dplyr::filter(checkResults, .data$checkName == "measureValueCompleteness" &
        .data$numDenominatorRows == 0 &
        .data$isError == 0 &
        is.na(.data$tableIsMissing) &
        is.na(.data$fieldIsMissing)),
      "cdmTableName"
    )
  )
  if (nrow(emptyTables) > 0) {
    emptyTables$tableIsEmpty <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, emptyTables, by = c("cdmTableName")),
      tableIsEmpty = ifelse(.data$checkName != "cdmField" & .data$checkName != "cdmTable" & .data$isError == 0, .data$tableIsEmpty, NA)
    )
  } else {
    checkResults$tableIsEmpty <- NA
  }

  emptyFields <-
    dplyr::select(
      dplyr::filter(checkResults, .data$checkName == "measureValueCompleteness" &
        .data$numDenominatorRows == .data$numViolatedRows &
        is.na(.data$tableIsMissing) & is.na(.data$fieldIsMissing) & is.na(.data$tableIsEmpty)),
      "cdmTableName", "cdmFieldName"
    )
  if (nrow(emptyFields) > 0) {
    emptyFields$fieldIsEmpty <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, emptyFields, by = c("cdmTableName", "cdmFieldName")),
      fieldIsEmpty = ifelse(.data$checkName != "measureValueCompleteness" & .data$checkName != "cdmField" & .data$checkName != "isRequired" & .data$isError == 0, .data$fieldIsEmpty, NA)
    )
  } else {
    checkResults$fieldIsEmpty <- NA
  }

  checkResults <- dplyr::mutate(
    checkResults,
    conceptIsMissing = ifelse(
      .data$isError == 0 &
        is.na(.data$tableIsMissing) &
        is.na(.data$fieldIsMissing) &
        is.na(.data$tableIsEmpty) &
        is.na(.data$fieldIsEmpty) &
        .data$checkLevel == "CONCEPT" &
        is.na(.data$unitConceptId) &
        .data$numDenominatorRows == 0,
      1,
      NA
    )
  )

  checkResults <- dplyr::mutate(
    checkResults,
    conceptAndUnitAreMissing = ifelse(
      .data$isError == 0 &
        is.na(.data$tableIsMissing) &
        is.na(.data$fieldIsMissing) &
        is.na(.data$tableIsEmpty) &
        is.na(.data$fieldIsEmpty) &
        .data$checkLevel == "CONCEPT" &
        !is.na(.data$unitConceptId) &
        .data$numDenominatorRows == 0,
      1,
      NA
    )
  )

  checkResults <- dplyr::mutate(
    checkResults,
    notApplicable = dplyr::coalesce(.data$tableIsMissing, .data$fieldIsMissing, .data$tableIsEmpty, .data$fieldIsEmpty, .data$conceptIsMissing, .data$conceptAndUnitAreMissing, 0),
    notApplicableReason = dplyr::case_when(
      !is.na(.data$tableIsMissing) ~ sprintf("Table %s does not exist.", .data$cdmTableName),
      !is.na(.data$fieldIsMissing) ~ sprintf("Field %s.%s does not exist.", .data$cdmTableName, .data$cdmFieldName),
      !is.na(.data$tableIsEmpty) ~ sprintf("Table %s is empty.", .data$cdmTableName),
      !is.na(.data$fieldIsEmpty) ~ sprintf("Field %s.%s is not populated.", .data$cdmTableName, .data$cdmFieldName),
      !is.na(.data$conceptIsMissing) ~ sprintf("%s=%s is missing from the %s table.", .data$cdmFieldName, .data$conceptId, .data$cdmTableName),
      !is.na(.data$conceptAndUnitAreMissing) ~ sprintf("Combination of %s=%s, unitConceptId=%s and VALUE_AS_NUMBER IS NOT NULL is missing from the %s table.", .data$cdmFieldName, .data$conceptId, .data$unitConceptId, .data$cdmTableName)
    )
  )

  checkResults <- dplyr::select(checkResults, -c("tableIsMissing", "fieldIsMissing", "tableIsEmpty", "fieldIsEmpty", "conceptIsMissing", "conceptAndUnitAreMissing"))
  checkResults <- dplyr::mutate(checkResults, failed = ifelse(.data$notApplicable == 1, 0, .data$failed))
  checkResults <- dplyr::mutate(checkResults, passed = ifelse(.data$failed == 0 & .data$isError == 0 & .data$notApplicable == 0, 1, 0))

  checkResults
}
