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

#' Internal function to evaluate the data quality checks against given thresholds.
#'
#' @param checkResults              A dataframe containing the results of the data quality checks
#' @param tableChecks               A dataframe containing the table checks
#' @param fieldChecks               A dataframe containing the field checks
#' @param conceptChecks             A dataframe containing the concept checks
#'
#' @keywords internal
#'

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
        if (is.na(checkResults[i, ]$unitConceptId)) {
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
    dplyr::filter(checkResults, checkName == "cdmTable" & failed == 1),
    cdmTableName
  )
  if (nrow(missingTables) > 0) {
    missingTables$tableIsMissing <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, missingTables, by = "cdmTableName"),
      tableIsMissing = ifelse(checkName != "cdmTable" & isError == 0, tableIsMissing, NA)
    )
  } else {
    checkResults$tableIsMissing <- NA
  }

  missingFields <- dplyr::select(
    dplyr::filter(checkResults, checkName == "cdmField" & failed == 1 & is.na(tableIsMissing)),
    cdmTableName, cdmFieldName
  )
  if (nrow(missingFields) > 0) {
    missingFields$fieldIsMissing <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, missingFields, by = c("cdmTableName", "cdmFieldName")),
      fieldIsMissing = ifelse(checkName != "cdmField" & isError == 0, fieldIsMissing, NA)
    )
  } else {
    checkResults$fieldIsMissing <- NA
  }

  emptyTables <- dplyr::distinct(
    dplyr::select(
      dplyr::filter(checkResults, checkName == "measureValueCompleteness" &
        numDenominatorRows == 0 &
        isError == 0 &
        is.na(tableIsMissing) &
        is.na(fieldIsMissing)),
      cdmTableName
    )
  )
  if (nrow(emptyTables) > 0) {
    emptyTables$tableIsEmpty <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, emptyTables, by = c("cdmTableName")),
      tableIsEmpty = ifelse(checkName != "cdmField" & checkName != "cdmTable" & isError == 0, tableIsEmpty, NA)
    )
  } else {
    checkResults$tableIsEmpty <- NA
  }

  emptyFields <-
    dplyr::select(
      dplyr::filter(checkResults, checkName == "measureValueCompleteness" &
        numDenominatorRows == numViolatedRows &
        is.na(tableIsMissing) & is.na(fieldIsMissing) & is.na(tableIsEmpty)),
      cdmTableName, cdmFieldName
    )
  if (nrow(emptyFields) > 0) {
    emptyFields$fieldIsEmpty <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, emptyFields, by = c("cdmTableName", "cdmFieldName")),
      fieldIsEmpty = ifelse(checkName != "measureValueCompleteness" & checkName != "cdmField" & checkName != "isRequired" & isError == 0, fieldIsEmpty, NA)
    )
  } else {
    checkResults$fieldIsEmpty <- NA
  }

  checkResults <- dplyr::mutate(
    checkResults,
    conceptIsMissing = ifelse(
      isError == 0 &
        is.na(tableIsMissing) &
        is.na(fieldIsMissing) &
        is.na(tableIsEmpty) &
        is.na(fieldIsEmpty) &
        checkLevel == "CONCEPT" &
        is.na(unitConceptId) &
        numDenominatorRows == 0,
      1,
      NA
    )
  )

  checkResults <- dplyr::mutate(
    checkResults,
    conceptAndUnitAreMissing = ifelse(
      isError == 0 &
        is.na(tableIsMissing) &
        is.na(fieldIsMissing) &
        is.na(tableIsEmpty) &
        is.na(fieldIsEmpty) &
        checkLevel == "CONCEPT" &
        !is.na(unitConceptId) &
        numDenominatorRows == 0,
      1,
      NA
    )
  )

  checkResults <- dplyr::mutate(
    checkResults,
    notApplicable = dplyr::coalesce(tableIsMissing, fieldIsMissing, tableIsEmpty, fieldIsEmpty, conceptIsMissing, conceptAndUnitAreMissing, 0),
    notApplicableReason = dplyr::case_when(
      !is.na(tableIsMissing) ~ sprintf("Table %s does not exist.", cdmTableName),
      !is.na(fieldIsMissing) ~ sprintf("Field %s.%s does not exist.", cdmTableName, cdmFieldName),
      !is.na(tableIsEmpty) ~ sprintf("Table %s is empty.", cdmTableName),
      !is.na(fieldIsEmpty) ~ sprintf("Field %s.%s is not populated.", cdmTableName, cdmFieldName),
      !is.na(conceptIsMissing) ~ sprintf("%s=%s is missing from the %s table.", cdmFieldName, conceptId, cdmTableName),
      !is.na(conceptAndUnitAreMissing) ~ sprintf("Combination of %s=%s, unitConceptId=%s and VALUE_AS_NUMBER IS NOT NULL is missing from the %s table.", cdmFieldName, conceptId, unitConceptId, cdmTableName)
    )
  )

  checkResults <- dplyr::select(checkResults, -c(tableIsMissing, fieldIsMissing, tableIsEmpty, fieldIsEmpty, conceptIsMissing, conceptAndUnitAreMissing))
  checkResults <- dplyr::mutate(checkResults, failed = ifelse(notApplicable == 1, 0, failed))
  checkResults <- dplyr::mutate(checkResults, passed = ifelse(failed == 0 & isError == 0 & notApplicable == 0, 1, 0))

  checkResults
}
