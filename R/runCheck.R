#' Internal function to run and process each data quality check.
#' 
#' @param checkDescription          The description of the data quality check
#' @param tablechecks               A dataframe containing the table checks
#' @param fieldChecks               A dataframe containing the field checks
#' @param conceptChecks             A dataframe containing the concept checks
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param connection                A connection for connecting to the CDM database using the DatabaseConnector::connect(connectionDetails) function.
#' @param cdmDatabaseSchema         The fully qualified database name of the CDM schema
#' @param vocabDatabaseSchema       The fully qualified database name of the vocabulary schema (default is to set it as the cdmDatabaseSchema)
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param cohortDatabaseSchema      The schema where the cohort table is located.
#' @param cohortDefinitionId        The cohort definition id for the cohort you wish to run the DQD on. The package assumes a standard OHDSI cohort table called 'Cohort' 
#' @param outputFolder              The folder to output logs and SQL files to
#' @param sqlOnlyUnionCount         How many SQL commands to union before inserting them into output table (speeds processing when queries done in parallel)
#' @param sqlOnly                   Should the SQLs be executed (FALSE) or just returned (TRUE)?
#' 
#' @import magrittr
#' 
#' @keywords internal
#' 
#' TODO: create a sqlOnly '.runCheck' function
.runCheck <- function(checkDescription, 
                      tableChecks,
                      fieldChecks,
                      conceptChecks,
                      connectionDetails,
                      connection,
                      cdmDatabaseSchema, 
                      vocabDatabaseSchema,
                      resultsDatabaseSchema,
                      cohortDatabaseSchema,
                      cohortDefinitionId,
                      outputFolder, 
                      sqlOnlyUnionCount,
                      sqlOnly) {
  ParallelLogger::logInfo(sprintf("Processing check description: %s", checkDescription$checkName))
  
  filterExpression <- sprintf("%sChecks %%>%% dplyr::filter(%s)",
                              tolower(checkDescription$checkLevel),
                              checkDescription$evaluationFilter)
  checks <- eval(parse(text = filterExpression))
  
  if (length(cohortDefinitionId > 0)){cohort = TRUE} else {cohort = FALSE}
  
  if (nrow(checks) <= 0) {
    ParallelLogger::logWarn(paste0("Warning: Evaluation resulted in no checks: ", filterExpression))
    return(data.frame())
  }
  
  if (sqlOnly) {
    # Global variables for tracking SQL of checks
    sql_to_union <<- c()
    qnum <<- 0
    unlink(file.path(outputFolder, sprintf("%s.sql", checkDescription$checkName)))
  }
  
  dfs <- apply(X = checks, MARGIN = 1, function(check) {
    
    columns <- lapply(names(check), function(c) {
      setNames(check[c], c)
    })
    
    params <- c(list(dbms = connectionDetails$dbms),
                list(sqlFilename = checkDescription$sqlFile),
                list(packageName = "DataQualityDashboard"),
                list(warnOnMissingParameters = FALSE),
                list(cdmDatabaseSchema = cdmDatabaseSchema),
                list(cohortDatabaseSchema = cohortDatabaseSchema),
                list(cohortDefinitionId = cohortDefinitionId),
                list(vocabDatabaseSchema = vocabDatabaseSchema),
                list(cohort = cohort),
                unlist(columns, recursive = FALSE))
    
    sql <- do.call(SqlRender::loadRenderTranslateSql, params)
    
    if (sqlOnly) {
      .createSqlOnlyQuery(params, check, tableChecks, fieldChecks, conceptChecks, sql, connectionDetails, resultsDatabaseSchema, outputFolder, checkDescription, sqlOnlyUnionCount)
      data.frame()
    } else {
      .processCheck(connection = connection,
                                            connectionDetails = connectionDetails,
                                            check = check, 
                                            checkDescription = checkDescription, 
                                            sql = sql,
                                            outputFolder = outputFolder)
    }
  })

  if (sqlOnly && sqlOnlyUnionCount > 1 && length(sql_to_union) > 0) {
    # Now write union of 'sqlOnlyUnionCount' at a time SQL statements
    ustart <- 1
    uend <- 1

    while (ustart <= length(sql_to_union)) {
      uend <- min(ustart + sqlOnlyUnionCount - 1, length(sql_to_union))

      apart <- sql_to_union[ustart:uend]

      sql_unioned <- paste(apart,collapse=' UNION ALL ')
      
      sql4 <- SqlRender::loadRenderTranslateSql(
        sqlFilename = "insert_ctes_into_result_table.sql"
        ,packageName = "DataQualityDashboard"
        ,tableName = "dqdashboard_results"
        ,resultsDatabaseSchema = resultsDatabaseSchema
        ,dbms = connectionDetails$dbms
        ,query_text = sql_unioned    
      )
      write(
        x = sql4,
        file = file.path(
          outputFolder, 
          sprintf("%s.sql", checkDescription$checkName)
        ), 
        append = TRUE)
      
      ustart <- ustart + sqlOnlyUnionCount
    }
  }
  do.call(rbind, dfs)
}
