#' Write DQD results to json
#' 
#' @param result           A DQD results object (list)
#' @param outputFolder     The output folder
#' @param outputFile       The output filename

#' @keywords internal

.writeResultsToJson <- function(result, outputFolder, outputFile) {
  resultJson <- jsonlite::toJSON(result)
  
  resultFilename <- file.path(outputFolder, outputFile)
  result$outputFile <- outputFile
  
  ParallelLogger::logInfo(sprintf("Writing results to file: %s", resultFilename))
  write(resultJson, resultFilename)
}

#' Internal function to write the check results to a table in the database. Requires write access to the database
#' 
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param checkResults              A dataframe containing the fully summarized data quality check results
#' @param writeTableName            The name of the table to be written to the database. Default is "dqdashboard_results".
#' @param cohortDefinitionId        (OPTIONAL) The cohort definition id for the cohort you wish to run the DQD on. The package assumes a standard OHDSI cohort table called 'Cohort' 
#'                                  with the fields cohort_definition_id and subject_id.
#' @keywords internal

.writeResultsToTable <- function(connectionDetails,
                                 resultsDatabaseSchema,
                                 checkResults,
                                 writeTableName,
                                 cohortDefinitionId) {
  
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))
  
  if (length(cohortDefinitionId > 0)){
    tableName <- sprintf("%s.%s_%s", resultsDatabaseSchema,writeTableName, cohortDefinitionId)
  } else {tableName <- sprintf("%s.%s", resultsDatabaseSchema, writeTableName)}
  
  ParallelLogger::logInfo(sprintf("Writing results to table %s", tableName))
  
  ddl <- SqlRender::loadRenderTranslateSql(sqlFilename = "result_dataframe_ddl.sql", packageName = "DataQualityDashboard", tableName = tableName, dbms = connectionDetails$dbms)
  
  DatabaseConnector::executeSql(connection = connection, sql = ddl, progressBar = TRUE)
  
  tryCatch(
    expr = {
      DatabaseConnector::insertTable(connection = connection, tableName = tableName, data = checkResults, 
                                     dropTableIfExists = FALSE, createTable = FALSE, tempTable = FALSE)
      ParallelLogger::logInfo("Finished writing table")
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("Writing table failed: %s", e$message))
    }
  )
}

#' Internal function to write the check results to a csv file.
#' 
#' @param checkResults              A dataframe containing the fully summarized data quality check results
#' @param csvPath                   The path where the csv file should be written
#' @param columns                   The columns to be included in the csv file. Default is all columns in the checkResults dataframe.
#' @param delimiter                 The delimiter for the file. Default is comma.
#' 
#' @keywords internal

.writeResultsToCsv <- function(checkResults,
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
      ParallelLogger::logInfo(sprintf("Writing results to CSV file %s", csvPath))
      columns <- intersect(union(c("checkId", "FAILED", "PASSED", "IS_ERROR", "NOT_APPLICABLE"), columns), colnames(checkResults))
      if (is.element("QUERY_TEXT", columns)) {
        checkResults$QUERY_TEXT <- stringr::str_replace_all(checkResults$QUERY_TEXT, "\n", " ")
        checkResults$QUERY_TEXT <- stringr::str_replace_all(checkResults$QUERY_TEXT, "\r", " ")
        checkResults$QUERY_TEXT <- stringr::str_replace_all(checkResults$QUERY_TEXT, "\t", " ")
      }
      if (is.element("ERROR", columns)) {
        checkResults$ERROR <- stringr::str_replace_all(checkResults$ERROR, "\n", " ")
        checkResults$ERROR <- stringr::str_replace_all(checkResults$ERROR, "\r", " ")
        checkResults$ERROR <- stringr::str_replace_all(checkResults$ERROR, "\t", " ")
      }
      write.table(dplyr::select(checkResults, columns), file = csvPath, sep = delimiter, row.names = FALSE, na = "")
      ParallelLogger::logInfo("Finished writing to CSV file")
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("Writing to CSV file failed: %s", e$message))
    }
  )
}