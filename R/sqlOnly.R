
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
    resultsDatabaseSchema,
    outputFolder,
    checkDescription,
    sqlOnlyUnionCount
) {
  check_description = SqlRender::render(
    sql = checkDescription$checkDescription
    ,warnOnMissingParameters = FALSE
    ,cdmFieldName = params$cdmFieldName
    ,cdmTableName = params$cdmTableName
    ,conceptId = params$conceptId
    ,conceptName = params$conceptName
    ,unitConceptId = params$unitConceptId
    ,unitConceptName = params$unitConceptName
    ,plausibleGender = params$plausibleGender
    ,plausibleValueHigh = params$plausibleValueHigh
    ,plausibleValueLow = params$plausibleValueLow
    ,fkClass = params$fkClass
    ,fkDomain = params$fkDomain
    ,fkTableName = params$fkTableName
    ,plausibleTemporalAfterFieldName = params$plausibleTemporalAfterFieldName
    ,plausibleTemporalAfterTableName = params$plausibleTemporalAfterTableName
  )
  
  thresholdValue <- .evaluateOneThreshold(
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
  
  qnum <<- qnum + 1
  
  sql3 <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "cte_sql_for_results_table.sql"
    ,packageName = "DataQualityDashboard"
    ,dbms = connectionDetails$dbms
    ,query_text = gsub(";", "", sql)
    ,check_name = checkDescription$checkName
    ,check_level = checkDescription$checkLevel
    ,check_description = check_description
    ,cdm_table_name = check["cdmTableName"]
    ,cdm_field_name = check["cdmFieldName"]
    ,concept_id = check["conceptId"]
    ,unit_concept_id = check["unitConceptId"]
    ,sql_file = checkDescription$sqlFile
    ,category = checkDescription$kahnCategory
    ,subcategory = checkDescription$kahnSubcategory
    ,context = checkDescription$kahnContext
    ,checkid = .getCheckId(checkDescription$checkLevel, checkDescription$checkName, check["cdmTableName"], check["cdmFieldName"], check["conceptId"], check["unitConceptId"])
    ,threshold_value = thresholdValue
    ,query_num = qnum
  )
  
  sql_to_union <<- append(sql_to_union, sql3)

  if (sqlOnlyUnionCount <= 1) {
    sql4 <- SqlRender::loadRenderTranslateSql(
      sqlFilename = "insert_ctes_into_result_table.sql"
      ,packageName = "DataQualityDashboard"
      ,tableName = "dqdashboard_results"  # TODO: this should be a variable 
      ,resultsDatabaseSchema = resultsDatabaseSchema
      ,dbms = connectionDetails$dbms
      ,query_text = sql3    
    )          
    write(
      x = sql4, 
      file = file.path(
        outputFolder, 
        sprintf("%s.sql", checkDescription$checkName)
      ), 
      append = TRUE
    )
  }
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
  dbms,
  outputFolder,
  checkName
) {
  ustart <- 1
  
  while (ustart <= length(sql_to_union)) {
    uend <- min(ustart + sqlOnlyUnionCount - 1, length(sql_to_union))
    
    apart <- sql_to_union[ustart:uend]
    
    sql_unioned <- paste(apart, collapse=' UNION ALL ')
    
    sql4 <- SqlRender::loadRenderTranslateSql(
      sqlFilename = "insert_ctes_into_result_table.sql"
      ,packageName = "DataQualityDashboard"
      ,tableName = "dqdashboard_results"
      ,resultsDatabaseSchema = resultsDatabaseSchema
      ,dbms = dbms
      ,query_text = sql_unioned    
    )
    write(
      x = sql4,
      file = file.path(
        outputFolder, 
        sprintf("%s.sql", checkName)
      ), 
      append = TRUE)
    
    ustart <- ustart + sqlOnlyUnionCount
  }
}
    