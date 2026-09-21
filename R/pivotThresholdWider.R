# Copyright 2026 Observational Health Data Sciences and Informatics
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


#' Transforms a long-format DQD threshold object to expected wide format.
#' 
#' @param threshold Long format threshold object
#' 
#' @return threshold in wide format
#' 
#' @keywords internal
#' @noRd
.pivotThresholdWider <- function(threshold) {
  threshold <- .normalizeNames(threshold)

  if ('conceptId' %in% names(threshold)) {
    # Concept Level -----------------------
    .pivotWider(
      threshold,
      values_from = c('checkParameter', 'Threshold', 'Notes')
    )
  } else if ('cdmFieldName' %in% names(threshold)) {
    # Field Level -------------------------
    .pivotWider(
      threshold,
      values_from = c('checkParameter', 'Threshold', 'Notes', 'checkParameter_TableName', 'checkParameter_FieldName')
    ) |>
    # Wide level field threshold has inconsistent column names (left). Rename only if column exists
    dplyr::rename(any_of(c(
      fkTableName = 'isForeignKeyTableName',
      fkFieldName = 'isForeignKeyFieldName',
      standardConceptFieldName = 'sourceValueCompletenessFieldName'
    )))
  } else {
    # Table Level -------------------------
    .pivotWider(
      threshold,
      values_from = c('checkParameter', 'Threshold', 'Notes')
    ) |>
    # remove redundant columns for cdmTable check, these are implicit when processing wide-format
    dplyr::select(
      !c('cdmTable', 'cdmTableThreshold', 'cdmTableNotes')
    ) |>
    # needs schema where to find tables (CDM, COHORT or VOCAB). Here we always set to CDM schema.
    dplyr::mutate(
      schema = 'CDM',
      .after = cdmTableName
    )
  }
}

#' Generic function for DQD threshold long to wide format.
#' 
#' @param threshold Long format threshold object
#' @param values_from list of column names to pivot, differs per check level
#' 
#' @return threshold table in wide format
#' 
#' @keywords internal
#' @noRd
.pivotWider <- function(threshold, values_from) {
  if (!('checkParameter' %in% names(threshold))) {
    threshold$checkParameter <- NA
  }

  threshold |>
    dplyr::mutate(
      checkParameter = dplyr::coalesce(checkParameter, 'Yes'),
      Threshold = dplyr::coalesce(Threshold, 100),
      Notes = dplyr::coalesce(Notes, '')
    ) |>
    tidyr::pivot_wider(
      names_from = checkName,
      names_glue = '{checkName}{.value}',
      values_from = all_of(values_from),
      names_sort = TRUE,
      values_fill = list(checkParameter = NA, Notes = '')
    ) |>
    dplyr::rename_with(
      ~ sub('checkParameter_?', '', .x)
    ) |>
    dplyr::select_if(
      function(x) !(all(is.na(x)))
    )
}

.normalizeNames <- function(threshold) {
  # Allow two sets of column names in long format, consistent (right) and in-line with wide-level threshold (left)
  threshold |>
    dplyr::rename(any_of(c(
      cdmTableName = 'tableName',
      cdmFieldName = 'fieldName',
      Threshold = 'threshold',
      Notes = 'notes',
      checkParameter_TableName = 'yTableName',
      checkParameter_FieldName = 'yFieldName'
    ))) 
}
