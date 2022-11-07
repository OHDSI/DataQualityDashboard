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
#' @param cohortDatabaseSchema      The schema where the cohort table is located.
#' @param cohortDefinitionId        The cohort definition id for the cohort you wish to run the DQD on. The package assumes a standard OHDSI cohort table called 'Cohort' 
#' @param outputFolder              The folder to output logs and SQL files to
#' @param sqlOnly                   Should the SQLs be executed (FALSE) or just returned (TRUE)?
#' 
#' @import magrittr
#' 
#' @keywords internal
#' 
.runCheck <- function(checkDescription, 
                      tableChecks,
                      fieldChecks,
                      conceptChecks,
                      connectionDetails,
                      connection,
                      cdmDatabaseSchema, 
                      vocabDatabaseSchema,
                      cohortDatabaseSchema,
                      cohortDefinitionId,
                      outputFolder, 
                      sqlOnly) {
 
  ParallelLogger::logInfo(sprintf("Processing check description: %s", checkDescription$checkName))
  
  filterExpression <- sprintf("%sChecks %%>%% dplyr::filter(%s)",
                              tolower(checkDescription$checkLevel),
                              checkDescription$evaluationFilter)
  checks <- eval(parse(text = filterExpression))
  
  if (length(cohortDefinitionId > 0)){cohort = TRUE} else {cohort = FALSE}
  
  if (sqlOnly) {
    unlink(file.path(outputFolder, sprintf("%s.sql", checkDescription$checkName)))
  }
  
  if (nrow(checks) > 0) {
    dfs <- apply(X = checks, MARGIN = 1, function(check) {
      
      columns <- lapply(names(check), function(c) {
        setNames(check[c], c)
      })
      
      packageName <- if(!is.null(checkDescription$packageName)) checkDescription$packageName else "DataQualityDashboard"
      
      params <- c(list(dbms = connectionDetails$dbms),
                  list(sqlFilename = checkDescription$sqlFile),
                  list(packageName = packageName),
                  list(warnOnMissingParameters = FALSE),
                  list(cdmDatabaseSchema = cdmDatabaseSchema),
                  list(cohortDatabaseSchema = cohortDatabaseSchema),
                  list(cohortDefinitionId = cohortDefinitionId),
                  list(vocabDatabaseSchema = vocabDatabaseSchema),
                  list(cohort = cohort),
                  unlist(columns, recursive = FALSE))
      
      sql <- do.call(SqlRender::loadRenderTranslateSql, params)
      
      if (sqlOnly) {
        write(x = sql, file = file.path(outputFolder, 
                                        sprintf("%s.sql", checkDescription$checkName)), append = TRUE)
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
    do.call(rbind, dfs)
  } else {
    ParallelLogger::logWarn(paste0("Warning: Evaluation resulted in no checks: ", filterExpression))
    data.frame()
  }
}
