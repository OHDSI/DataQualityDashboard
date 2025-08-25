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

#' Internal function to create queries when running in "incremental insert" sqlOnly mode
#'
#' @param params                    Collection of parameters from .runCheck
#' @param check                     Create SQL for this specific check type
#' @param tablechecks               A dataframe containing the table checks
#' @param fieldChecks               A dataframe containing the field checks
#' @param conceptChecks             A dataframe containing the concept checks
#' @param sql                       The rendered SQL for this check
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param checkDescription          The description of the data quality check
#'
#' @return A rendered SQL query to add into the incremental insert sqlOnly query

#' @noRd
#' @keywords internal
#'
.createSqlOnlyQueries <- function(
    params,
    check,
    tableChecks,
    fieldChecks,
    conceptChecks,
    sql,
    connectionDetails,
    checkDescription) {
  resultShell <- .recordResult(check = check, checkDescription = checkDescription, sql = sql)

  resultShell$queryText <- gsub(";", "", resultShell$queryText)
  resultShell$checkDescription <- gsub("\t", " ", gsub("\r", " ", gsub("\n", " ", gsub("'", "''", resultShell$checkDescription))))

  # Retrieve the numeric threshold value for the specific check.
  thresholdValue <- .getThreshold(
    checkName = resultShell$checkName,
    checkLevel = resultShell$checkLevel,
    cdmTableName = resultShell$cdmTableName,
    cdmFieldName = resultShell$cdmFieldName,
    conceptId = resultShell$conceptId,
    unitConceptId = resultShell$unitConceptId,
    tableChecks = tableChecks,
    fieldChecks = fieldChecks,
    conceptChecks = conceptChecks
  )

  # Generate the wrapping query for the desired check. This creates a final row for insertion that includes nearly all the metadata for the query (in addition to calling the check query itself)
  # The only metadata that are not included in this wrapping query include:
  # 1. execution_time -- since this query is not being executed (only the SQL is generated), execution_time is not available
  # 2. queryText -- although this could be included, it seemed redundant since it is part of the generated SQL file
  # 3. warning -- not available since the SQL is not executed
  # 4. error -- not available since the SQL is not executed
  # 5. not_applicable_reason -- this currently requires post-processing
  # 6. notes_value -- although this could be included, it seemed redundant
  checkQuery <- SqlRender::loadRenderTranslateSql(
    sqlFilename = file.path("sqlOnly", "cte_sql_for_results_table.sql"),
    packageName = "DataQualityDashboard",
    dbms = connectionDetails$dbms,
    queryText = resultShell$queryText,
    checkName = resultShell$checkName,
    checkLevel = resultShell$checkLevel,
    renderedCheckDescription = resultShell$checkDescription,
    cdmTableName = resultShell$cdmTableName,
    cdmFieldName = resultShell$cdmFieldName,
    conceptId = resultShell$conceptId,
    unitConceptId = resultShell$unitConceptId,
    sqlFile = checkDescription$sqlFile,
    category = resultShell$category,
    subcategory = resultShell$subcategory,
    context = resultShell$context,
    checkId = resultShell$checkId,
    thresholdValue = thresholdValue
  )

  return(checkQuery)
}


#' Internal function to write queries when running in sqlOnly mode
#'
#' @param sqlToUnion                List of one or more SQL queries to union
#' @param sqlOnlyUnionCount         Value of @sqlOnlyUnionCount - determines max # of sql queries to union in a single cte
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param writeTableName            The table tor write DQD results to. Used when sqlOnly or writeToTable is True.
#' @param dbms                      The database type (e.g. spark, sql server) - needed for proper query rendering
#' @param outputFolder              Location to write the generated SQL files
#' @param checkDescription          The description of the data quality check

#' @noRd
#' @keywords internal
#'
.writeSqlOnlyQueries <- function(
    sqlToUnion,
    sqlOnlyUnionCount,
    resultsDatabaseSchema,
    writeTableName,
    dbms,
    outputFolder,
    checkDescription) {
  outFile <- file.path(
    outputFolder,
    sprintf("%s_%s.sql", checkDescription$checkLevel, checkDescription$checkName)
  )

  # Delete existing file
  unlink(outFile)

  ustart <- 1
  while (ustart <= length(sqlToUnion)) {
    uend <- min(ustart + sqlOnlyUnionCount - 1, length(sqlToUnion))

    sqlUnioned <- paste(sqlToUnion[ustart:uend], collapse = " UNION ALL ")

    # Generate INSERT commands to insert results + metadata into results table
    sql <- SqlRender::loadRenderTranslateSql(
      sqlFilename = file.path("sqlOnly", "insert_ctes_into_result_table.sql"),
      packageName = "DataQualityDashboard",
      dbms = dbms,
      resultsDatabaseSchema = resultsDatabaseSchema,
      tableName = writeTableName,
      queryText = sqlUnioned
    )

    write(
      x = sql,
      file = outFile,
      append = TRUE
    )

    ustart <- ustart + sqlOnlyUnionCount
  }
}


#' Internal function to write the DDL to outputFolder

#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param writeTableName            The table tor write DQD results to. Used when sqlOnly or writeToTable is True.
#' @param dbms                      The database type (e.g. spark, sql server) - needed for proper query rendering
#' @param outputFolder              Location to write the generated SQL files

#' @noRd
#' @keywords internal
.writeDDL <- function(
    resultsDatabaseSchema,
    writeTableName,
    dbms,
    outputFolder) {
  tableName <- sprintf("%s.%s", resultsDatabaseSchema, writeTableName)

  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "result_dataframe_ddl.sql",
    packageName = "DataQualityDashboard",
    dbms = dbms,
    tableName = tableName
  )

  write(
    x = sql,
    file = file.path(
      outputFolder,
      "ddlDqdResults.sql"
    )
  )
}


#' Internal function to get one threshold
#' Note: this does not evaluate is_error or not_applicable status

#' @param checkName                 The name of the check - such as measurePersonCompleteness
#' @param checkLevel                The check level - such as TABLE
#' @param cdmTableName              The name of the CDM table - such as MEASUREMENT
#' @param cdmFieldName              Then name of the CDM field - such as MEASUREMENT_CONCEPT_ID
#' @param conceptId                 The specific concept_id being checked - a valid concept_id number
#' @param unitConceptId             The specific unit concept id being checked - a valid concept_id number
#' @param tableChecks               A dataframe containing the table checks
#' @param fieldChecks               A dataframe containing the field checks
#' @param conceptChecks             A dataframe containing the concept checks

#' @noRd
#' @keywords internal
.getThreshold <- function(
    checkName,
    checkLevel,
    cdmTableName,
    cdmFieldName,
    conceptId,
    unitConceptId,
    tableChecks,
    fieldChecks,
    conceptChecks) {
  thresholdField <- sprintf("%sThreshold", checkName)

  # find if field exists -----------------------------------------------
  thresholdFieldExists <- eval(parse(
    text = sprintf(
      "'%s' %%in%% colnames(%sChecks)",
      thresholdField,
      tolower(checkLevel)
    )
  ))

  if (!thresholdFieldExists) {
    thresholdValue <- NA
  } else {
    if (checkLevel == "TABLE") {
      thresholdFilter <- sprintf(
        "tableChecks$%s[tableChecks$cdmTableName == '%s']",
        thresholdField, cdmTableName
      )
    } else if (checkLevel == "FIELD") {
      thresholdFilter <- sprintf(
        "fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
        thresholdField,
        cdmTableName,
        cdmFieldName
      )
    } else if (checkLevel == "CONCEPT") {
      if (is.na(unitConceptId) &&
        grepl(",", conceptId)) {
        thresholdFilter <- sprintf(
          "conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == '%s']",
          thresholdField,
          cdmTableName,
          cdmFieldName,
          conceptId
        )
      } else if (is.na(unitConceptId) &&
        !grepl(",", conceptId)) {
        thresholdFilter <- sprintf(
          "conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s]",
          thresholdField,
          cdmTableName,
          cdmFieldName,
          conceptId
        )
      } else {
        thresholdFilter <- sprintf(
          "conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
          thresholdField,
          cdmTableName,
          cdmFieldName,
          conceptId,
          as.integer(unitConceptId)
        )
      }
    }
    thresholdValue <- eval(parse(text = thresholdFilter))
  }

  # Need value of 0 for NA in generated SQL
  if (is.na(thresholdValue)) {
    thresholdValue <- 0
  }

  thresholdValue
}
