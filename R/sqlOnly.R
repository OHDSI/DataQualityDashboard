
#' Internal function to create queries when running in SqlOnly mode
#' 
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
  qnum <<- qnum + 1
  
  check_description = SqlRender::render(
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
    fkClass = params$fkClass,
    fkDomain = params$fkDomain,
    fkTableName = params$fkTableName,
    plausibleTemporalAfterFieldName = params$plausibleTemporalAfterFieldName,
    plausibleTemporalAfterTableName = params$plausibleTemporalAfterTableName
  )
  
  thresholdValue <- .evaluateOneThresholdSqlOnly(
    check_name = checkDescription$checkName,
    check_level = checkDescription$checkLevel,
    cdm_table_name = check["cdmTableName"],
    cdm_field_name = check["cdmFieldName"],
    concept_id = check["conceptId"],
    unit_concept_id = check["unitConceptId"],
    tableChecks = tableChecks, 
    fieldChecks = fieldChecks,
    conceptChecks = conceptChecks
  )
  
  check_query <- SqlRender::loadRenderTranslateSql(
    sqlFilename = file.path("sqlOnly", "cte_sql_for_results_table.sql"),
    packageName = "DataQualityDashboard",
    dbms = connectionDetails$dbms,
    query_text = gsub(";", "", sql),
    check_name = checkDescription$checkName,
    check_level = checkDescription$checkLevel,
    check_description = check_description,  # TODO: escale quotes
    cdm_table_name = check["cdmTableName"],
    cdm_field_name = check["cdmFieldName"],
    concept_id = check["conceptId"],
    unit_concept_id = check["unitConceptId"],
    sql_file = checkDescription$sqlFile,
    category = checkDescription$kahnCategory,
    subcategory = checkDescription$kahnSubcategory,
    context = checkDescription$kahnContext,
    checkid = .getCheckId(checkDescription$checkLevel, checkDescription$checkName, check["cdmTableName"], check["cdmFieldName"], check["conceptId"], check["unitConceptId"]),
    threshold_value = thresholdValue,
    query_num = qnum
  )
  
  sql_to_union <<- append(sql_to_union, check_query)
}

#' Internal function to write queries when running in SqlOnly mode
#' 
#' @noRd
#' @keywords internal
#' 
.writeSqlOnlyQueries <- function(
  sql_to_union,
  sqlOnlyUnionCount,
  resultsDatabaseSchema,
  writeTableName,
  dbms,
  outputFolder,
  checkName
) {
  ustart <- 1
  
  while (ustart <= length(sql_to_union)) {
    uend <- min(ustart + sqlOnlyUnionCount - 1, length(sql_to_union))
    
    sql_unioned <- paste(sql_to_union[ustart:uend], collapse=' UNION ALL ')
    
    sql <- SqlRender::loadRenderTranslateSql(
      sqlFilename = file.path("sqlOnly", "insert_ctes_into_result_table.sql"),
      packageName = "DataQualityDashboard",
      dbms = dbms,
      resultsDatabaseSchema = resultsDatabaseSchema,
      tableName = writeTableName,
      query_text = sql_unioned    
    )
    
    write(
      x = sql,
      file = file.path(
        outputFolder, 
        sprintf("%s.sql", checkName)
      ), 
      append = TRUE)
    
    ustart <- ustart + sqlOnlyUnionCount
  }
}


#' Internal function to evaluate one threshold
#' Note: this does not evaluate is_error or not_applicable status
#' @noRd
#' @keywords internal
.evaluateOneThresholdSqlOnly <- function(
    check_name,
    check_level,
    cdm_table_name,
    cdm_field_name,
    concept_id,
    unit_concept_id,
    tableChecks,
    fieldChecks,
    conceptChecks
) {
  thresholdField <- sprintf("%sThreshold", check_name)
  
  # find if field exists -----------------------------------------------
  thresholdFieldExists <- eval(parse(
    text = sprintf("'%s' %%in%% colnames(%sChecks)", 
                   thresholdField, 
                   tolower(check_level)
    )))
  
  if (!thresholdFieldExists) {
    thresholdValue <- NA
  } else {
    if (check_level == "TABLE") {
      thresholdFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                                 thresholdField, cdm_table_name)
      
    } else if (check_level == "FIELD") {
      thresholdFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
                                 thresholdField, 
                                 cdm_table_name,
                                 cdm_field_name)
    } else if (check_level == "CONCEPT") {
      if (is.na(unit_concept_id)) {
        thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s]",
                                   thresholdField, 
                                   cdm_table_name,
                                   cdm_field_name,
                                   concept_id)
      } else {
        thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
                                   thresholdField, 
                                   cdm_table_name,
                                   cdm_field_name,
                                   concept_id,
                                   as.integer(unit_concept_id))
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
    