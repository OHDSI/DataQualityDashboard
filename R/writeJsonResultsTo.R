

#' Write JSON Results to SQL Table
#' 
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param jsonFilePath              Path to the JSON results file generated using the execute function
#' @param writeTableName            Name of table in the database to write results to
#' @param cohortDefinitionId        If writing results for a single cohort this is the ID that will be appended to the table name
#' 
#' @export

writeJsonResultsToTable <- function(connectionDetails,
                                    resultsDatabaseSchema,
                                    jsonFilePath,
                                    writeTableName = "dqdashboard_results",
                                    cohortDefinitionId = c()) {
  
  jsonData <- jsonlite::read_json(jsonFilePath)
  checkResults <- lapply(jsonData$CheckResults, function(cr) {
    cr[sapply(cr, is.null)] <- NA
    as.data.frame(cr)
  })
  
  df <- do.call(plyr::rbind.fill, checkResults)
  
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))
  
  if (length(cohortDefinitionId > 0)){
    tableName <- sprintf("%s.%s_%s", resultsDatabaseSchema,writeTableName, cohortDefinitionId)
  } else {tableName <- sprintf("%s.%s", resultsDatabaseSchema, writeTableName)}
  
  ParallelLogger::logInfo(sprintf("Writing results to table %s", tableName))
  
  if ("UNIT_CONCEPT_ID" %in% colnames(df)){
    ddl <- SqlRender::loadRenderTranslateSql(sqlFilename = "result_table_ddl_concept.sql", packageName = "DataQualityDashboard", tableName = tableName, dbms = connectionDetails$dbms)
  } else if ("CDM_FIELD_NAME" %in% colnames(df)){
    ddl <- SqlRender::loadRenderTranslateSql(sqlFilename = "result_table_ddl_field.sql", packageName = "DataQualityDashboard", tableName = tableName, dbms = connectionDetails$dbms)
  } else {
    ddl <- SqlRender::loadRenderTranslateSql(sqlFilename = "result_table_ddl_table.sql", packageName = "DataQualityDashboard", tableName = tableName, dbms = connectionDetails$dbms)
  }
  
  DatabaseConnector::executeSql(connection = connection, sql = ddl, progressBar = TRUE)
  
  tryCatch(
    expr = {
      DatabaseConnector::insertTable(connection = connection, tableName = tableName, data = df, 
                                     dropTableIfExists = FALSE, createTable = FALSE, tempTable = FALSE,
                                     progressBar = TRUE)
      ParallelLogger::logInfo("Finished writing table")
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("Writing table failed: %s", e$message))
    }
  )
  
  # .writeResultsToTable(connectionDetails = connectionDetails,
  #                      resultsDatabaseSchema = resultsDatabaseSchema,
  #                      checkResults = df)
}


#' Write JSON Results to CSV file
#' 
#' @param jsonPath    Path to the JSON results file generated using the execute function
#' @param csvPath     Path to the CSV output file
#' @param columns     (OPTIONAL) List of desired columns
#' @param delimiter   (OPTIONAL) CSV delimiter
#' 
#' @export

writeJsonResultsToCsv <- function(jsonPath,
                                  csvPath,
                                  columns = c("checkId", "FAILED", "PASSED", 
                                              "IS_ERROR", "NOT_APPLICABLE",
                                              "CHECK_NAME", "CHECK_DESCRIPTION",
                                              "THRESHOLD_VALUE", "NOTES_VALUE",
                                              "CHECK_LEVEL", "CATEGORY",
                                              "SUBCATEGORY", "CONTEXT",
                                              "CHECK_LEVEL", "CDM_TABLE_NAME",
                                              "CDM_FIELD_NAME", "CONCEPT_ID",
                                              "UNIT_CONCEPT_ID", "NUM_VIOLATED_ROWS",
                                              "PCT_VIOLATED_ROWS", "NUM_DENOMINATOR_ROWS",
                                              "EXECUTION_TIME", "NOT_APPLICABLE_REASON",
                                              "ERROR", "QUERY_TEXT"),
                                  delimiter = ",") {
  tryCatch(
    expr = {
      ParallelLogger::logInfo(sprintf("Loading results from %s", jsonPath))
      jsonData <- jsonlite::read_json(jsonPath)
      checkResults <- lapply(jsonData$CheckResults, function(cr) {
        cr[sapply(cr, is.null)] <- NA
        as.data.frame(cr)
      })
      .writeResultsToCsv(checkResults = do.call(plyr::rbind.fill, checkResults), csvPath, columns, delimiter)
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("Writing to CSV file failed: %s", e$message))
    }
  )
}
