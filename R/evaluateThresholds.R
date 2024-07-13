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

  if (.hasNAchecks(checkResults)) {
    checkResults <- .calculateNotApplicableStatus(checkResults)
  }

  checkResults
}
