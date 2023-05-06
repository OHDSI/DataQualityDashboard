# Copyright 2023 Observational Health Data Sciences and Informatics
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

#' @file sqlOnly.R

#' @title Create Sql Only Queries
#'
#' @description Internal function to create queries when running in SqlOnly mode
#'
#' @param params                    Collection of parameters from .runCheck
#' @param check                     Create SQL for this specific check level
#' @param tablechecks               A dataframe containing the table checks
#' @param fieldChecks               A dataframe containing the field checks
#' @param conceptChecks             A dataframe containing the concept checks
#' @param sql                       The rendered SQL for this check
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param checkDescription          The description of the data quality check
#'
#' @return A list of one or more sql queries to union

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
    checkDescription
) {
  # Update the global variable counting the number of queries that should be unioned together (based upon the sqlOnlyUnionCount parameter)
  globalQueryNum <<- globalQueryNum + 1
  
  # Retrieve the formatted string check description to be inserted in the check_description variable in the dqdashboard_results (@writeTableName) table
  # SqlRender is called in order to do variable substitution of parameters within the check_description template string
  # For example, the checkDescription for checkName = plausibleValueLow is:
  #          The number and percent of records with a value in the @cdmFieldName field of the @cdmTableName table less than @plausibleValueLow.
  # SqlRender updates that string to do @ parameter substitution.
  renderedCheckDescription <- SqlRender::render(
    sql = checkDescription$checkDescription,
    warnOnMissingParameters = FALSE,
    cdmFieldName = params$cdmFieldName,
    cdmTableName = params$cdmTableName,
    conceptId = params$conceptId,
    conceptName = params$conceptName,
    unitConceptId = params$unitConceptId,
    unitConceptName = params$unitConceptName,
    plausibleGender = params$plausibleGender,
    plausibleValueHigh = params$plausibleValueHigh,
    plausibleValueLow = params$plausibleValueLow,
    plausibleUnitConceptIds = params$plausibleUnitConceptIds,
    fkClass = params$fkClass,
    fkDomain = params$fkDomain,
    fkTableName = params$fkTableName,
    plausibleTemporalAfterFieldName = params$plausibleTemporalAfterFieldName,
    plausibleTemporalAfterTableName = params$plausibleTemporalAfterTableName
  )
  renderedCheckDescription <- gsub("'", "''", renderedCheckDescription)
  renderedCheckDescription <- gsub("\n", " ", renderedCheckDescription)
  renderedCheckDescription <- gsub("\r", " ", renderedCheckDescription)
  renderedCheckDescription <- gsub("\t", " ", renderedCheckDescription)

  
  # Retrieve the numeric threshold value for the specific check.
  thresholdValue <- .getThreshold(
    checkName = checkDescription$checkName,
    checkLevel = checkDescription$checkLevel,
    cdmTableName = check["cdmTableName"],
    cdmFieldName = check["cdmFieldName"],
    conceptId = check["conceptId"],
    unitConceptId = check["unitConceptId"],
    tableChecks = tableChecks, 
    fieldChecks = fieldChecks,
    conceptChecks = conceptChecks
  )
  
  # Generate the wrapping query for the desired check. This creates a final row for insertion that includes nearly all the metadata for the query (in addition to calling the check query itself)
  # The only metadata that are not included in this wrapping query include:
  # 1. execution_time -- since this query is not being executed (only the SQL is generated), execution_time is not available
  # 2. queryText -- although this could be included, it seemed redundant since it is part of  the generated SQL file
  # 3. warning -- not available since the SQL is not executed
  # 4. error -- not available since the SQL is not executed
  # 5. not_applicable_reason - this currently requires post-processing
  # 6. notes_value - although this could be included, it seemed redundant
  checkQuery <- SqlRender::loadRenderTranslateSql(
    sqlFilename = file.path("sqlOnly", "cte_sql_for_results_table.sql"),
    packageName = "DataQualityDashboard",
    dbms = connectionDetails$dbms,
    queryText = gsub(";", "", sql), # remove trailing semi-colon so can embed in a cte
    checkName = checkDescription$checkName,
    checkLevel = checkDescription$checkLevel,
    renderedCheckDescription = renderedCheckDescription,
    cdmTableName = check["cdmTableName"],
    cdmFieldName = check["cdmFieldName"],
    conceptId = check["conceptId"],
    unitConceptId = check["unitConceptId"],
    sqlFile = checkDescription$sqlFile,
    category = checkDescription$kahnCategory,
    subcategory = checkDescription$kahnSubcategory,
    context = checkDescription$kahnContext,
    checkId = .getCheckId(checkDescription$checkLevel, checkDescription$checkName, check["cdmTableName"], check["cdmFieldName"], check["conceptId"], check["unitConceptId"]),
    thresholdValue = thresholdValue,
    queryNum = globalQueryNum
  )

  # Add the final SQL to a list of SQL to append via UNION ALL
  globalSqlToUnion <<- append(globalSqlToUnion, checkQuery)
}


#' Internal function to write queries when running in SqlOnly mode
#' 
#' @param globalSqlToUnion          list of one or more SQL queries to union
#' @param sqlOnlyUnionCount         value of @sqlOnlyUnionCount - determines max # of sql queries to union in a single cte
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param writeTableName            The table tor write DQD results to. Used when sqlOnly or writeToTable is True.
#' @param dbms                      The database type (e.g. spark, sql server) - needed for proper query rendering
#' @param outputFolder              Location to write the generated SQL files
#' @param checkDescription          The description of the data quality check

#' @noRd
#' @keywords internal
#' 
.writeSqlOnlyQueries <- function(
  globalSqlToUnion,
  sqlOnlyUnionCount,
  resultsDatabaseSchema,
  writeTableName,
  dbms,
  outputFolder,
  checkDescription
) {
  outFile <-file.path(
    outputFolder, 
    sprintf("%s_%s.sql", checkDescription$checkLevel, checkDescription$checkName)
  )

  # Delete existing file
  unlink(outFile)

  ustart <- 1
  while (ustart <= length(globalSqlToUnion)) {
    uend <- min(ustart + sqlOnlyUnionCount - 1, length(globalSqlToUnion))
    
    sqlUnioned <- paste(globalSqlToUnion[ustart:uend], collapse=' UNION ALL ')
    
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
    outputFolder
) {
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
    conceptChecks
) {
  thresholdField <- sprintf("%sThreshold", checkName)
  
  # find if field exists -----------------------------------------------
  thresholdFieldExists <- eval(parse(
    text = sprintf("'%s' %%in%% colnames(%sChecks)", 
                   thresholdField, 
                   tolower(checkLevel)
    )))
  
  if (!thresholdFieldExists) {
    thresholdValue <- NA
  } else {
    if (checkLevel == "TABLE") {
      thresholdFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                                 thresholdField, cdmTableName)
      
    } else if (checkLevel == "FIELD") {
      thresholdFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
                                 thresholdField, 
                                 cdmTableName,
                                 cdmFieldName)
    } else if (checkLevel == "CONCEPT") {
      if (is.na(unitConceptId)) {
        thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s]",
                                   thresholdField, 
                                   cdmTableName,
                                   cdmFieldName,
                                   conceptId)
      } else {
        thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
                                   thresholdField, 
                                   cdmTableName,
                                   cdmFieldName,
                                   conceptId,
                                   as.integer(unitConceptId))
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
    