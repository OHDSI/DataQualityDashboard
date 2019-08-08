
.recordResult <- function(result = NULL, check, 
                          checkDescription, sql, 
                          executionTime = NA,
                          warning = NA, error = NA) {
  
  reportResult <- data.frame(
    NUM_VIOLATED_ROWS = NA,
    PCT_VIOLATED_ROWS = NA,
    EXECUTION_TIME = executionTime,
    QUERY_TEXT = sql,
    CHECK_NAME = checkDescription$CHECK_NAME,
    CHECK_LEVEL = checkDescription$CHECK_LEVEL,
    CHECK_DESCRIPTION = SqlRender::render(checkDescription$CHECK_DESCRIPTION, 
                                          CDM_FIELD = check["CDM_FIELD"], 
                                          CDM_TABLE = check["CDM_TABLE"], 
                                          PLAUSIBLE_VALUE_HIGH = check["PLAUSIBLE_VALUE_HIGH"],
                                          PLAUSIBLE_VALUE_LOW = check["PLAUSIBLE_VALUE_LOW"],
                                          STANDARD_CONCEPT_FIELD_NAME = check["STANDARD_CONCEPT_FIELD_NAME"],
                                          warnOnMissingParameters = FALSE),
    CDM_TABLE = check["CDM_TABLE"],
    CDM_FIELD = check["CDM_FIELD"],
    SQL_FILE = checkDescription$SQL_FILE,
    CATEGORY = checkDescription$KAHN_CATEGORY,
    SUBCATEGORY = checkDescription$KAHN_SUBCATEGORY,
    CONTEXT = checkDescription$KAHN_CONTEXT,
    WARNING = warning,
    ERROR = error, row.names = NULL, stringsAsFactors = FALSE
  )
  
  if (!is.null(result)) {
    reportResult$NUM_VIOLATED_ROWS <- result$NUM_VIOLATED_ROWS
    reportResult$PCT_VIOLATED_ROWS <- result$PCT_VIOLATED_ROWS
  }
  reportResult
}

.processCheck <- function(connectionDetails, check, checkDescription, sql, outputFolder) {
  start <- Sys.time()
  
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))

  errorReportFile <- file.path(outputFolder, "errors", 
                               sprintf("%s_%s_%s_%s.txt",
                                       checkDescription$CHECK_LEVEL,
                                       checkDescription$CHECK_NAME,
                                       check["CDM_TABLE"],
                                       check["CDM_FIELD"]))
  
  result <- DatabaseConnector::querySql(connection = connection, sql = sql, 
                                        errorReportFile = errorReportFile)
  
  delta <- Sys.time() - start
  .recordResult(result = result, check = check, checkDescription = checkDescription, sql = sql,  
                executionTime = sprintf("%f %s", delta, attr(delta, "units")))
}

#' Execute DQ checks
#' 
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param cdmDatabaseSchema         The fully qualified database name of the CDM schema
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param numThreads                The number of concurrent threads to use to execute the queries
#' @param cdmSourceName             The name of the CDM data source
#' @param sqlOnly                   Should the SQLs be executed (FALSE) or just returned (TRUE)?
#' @param outputFolder              The folder to output logs and SQL files to
#' @param verboseMode               Boolean to determine if the console will show all execution steps. Default = FALSE
#' @param writeToTable              Boolean to indicate if the check results will be written to the dqdashboard_results table
#'                                  in the resultsDatabaseSchema. Default is TRUE.
#' 
#' @return If sqlOnly = FALSE, a list object of results
#' 
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    cdmSourceName,
                    numThreads = 1,
                    sqlOnly = FALSE,
                    outputFolder = "output",
                    verboseMode = FALSE,
                    writeToTable = TRUE) {
  
  outputFolder <- file.path(outputFolder, cdmSourceName)
  
  if (!dir.exists(outputFolder)) {
    dir.create(path = outputFolder, recursive = TRUE)
  }
  
  if (dir.exists(file.path(outputFolder, "errors"))) {
    unlink(file.path(outputFolder, "errors"), recursive = TRUE)
  }
  
  dir.create(file.path(outputFolder, "errors"), recursive = TRUE)
  
  # Log execution -----------------------------------------------------------------------------------------------------------------
  ParallelLogger::clearLoggers()
  logFileName <- sprintf("log_DqDashboard_%s.txt", cdmSourceName)
  unlink(file.path(outputFolder, logFileName))
  
  if (verboseMode) {
    appenders <- list(ParallelLogger::createConsoleAppender(),
                      ParallelLogger::createFileAppender(layout = ParallelLogger::layoutParallel, 
                                                         fileName = file.path(outputFolder, logFileName)))    
  } else {
    appenders <- list(ParallelLogger::createFileAppender(layout = ParallelLogger::layoutParallel, 
                                                         fileName = file.path(outputFolder, logFileName)))    
  }
  

  logger <- ParallelLogger::createLogger(name = "DqDashboard",
                                         threshold = "INFO",
                                         appenders = appenders)
  ParallelLogger::registerLogger(logger)   
  
  # load CSVs ----------------------------------------------------------------------------------------
  
  startTime <- Sys.time()
  
  checkDescriptionsDf <- read.csv(system.file("csv", "OMOP_CDMv5.3.1_Check_Descriptions.csv", 
                                            package = "DataQualityDashboard"), 
                                stringsAsFactors = FALSE)
  fieldChecks <- read.csv(system.file("csv", "OMOP_CDMv5.3.1_Field_Level.csv",
                                      package = "DataQualityDashboard"), 
                          stringsAsFactors = FALSE)
  library(magrittr)
  fieldChecks <- fieldChecks %>% dplyr::select_if(function(x) !(all(is.na(x)) | all(x=="")))
  
  checkDescriptionsDf <- checkDescriptionsDf[checkDescriptionsDf$CHECK_LEVEL=="FIELD" & 
                                               checkDescriptionsDf$EVALUATION_FILTER != "",]
  
  checkDescriptions <- split(checkDescriptionsDf, seq(nrow(checkDescriptionsDf)))
  
  cluster <- ParallelLogger::makeCluster(numberOfThreads = numThreads, singleThreadToMain = TRUE)
  resultsList <- ParallelLogger::clusterApply(cluster = cluster, x = checkDescriptions,
                                              fun = .runCheck, fieldChecks,
                                              connectionDetails, cdmDatabaseSchema, 
                                              outputFolder, sqlOnly)
  ParallelLogger::stopCluster(cluster = cluster)
  
  allResults <- NULL
  if (!sqlOnly) {
    checkResults <- do.call("rbind", resultsList)
    checkResults$checkId <- seq.int(nrow(checkResults))
    
    allResults <- .summarizeResults(connectionDetails = connectionDetails, 
                      cdmDatabaseSchema = cdmDatabaseSchema, 
                      checkResults = checkResults,
                      cdmSourceName = cdmSourceName, 
                      outputFolder = outputFolder,
                      startTime = startTime)
    ParallelLogger::logInfo("Execution Complete")  
  }
  
  ParallelLogger::unregisterLogger("DqDashboard")
  
  # write to table ----------------------------------------------------------------------
  
  if (!sqlOnly & writeToTable) {
    .writeResultsToTable(connectionDetails = connectionDetails,
                         resultsDatabaseSchema = resultsDatabaseSchema,
                         checkResults = allResults$CheckResults)
  }
  
  if (sqlOnly) {
    invisible(allResults)
  } else {
    allResults  
  }
}

.runCheck <- function(checkDescription, 
                      fieldChecks, 
                      connectionDetails, 
                      cdmDatabaseSchema, 
                      outputFolder, 
                      sqlOnly) {
  
  library(magrittr)
  ParallelLogger::logInfo(sprintf("Processing check description: %s", checkDescription$CHECK_NAME))
  
  filterExpression <- paste0("fieldChecks %>% dplyr::filter(", checkDescription$EVALUATION_FILTER, ")")
  checks <- eval(parse(text = filterExpression))
  
  if (sqlOnly) {
    unlink(file.path(outputFolder, sprintf("%s.sql", checkDescription$CHECK_NAME)))
  }
  
  if (nrow(checks) > 0) {
    dfs <- apply(X = checks, MARGIN = 1, function(check) {
      sql <- SqlRender::loadRenderTranslateSql(
        dbms = connectionDetails$dbms,
        sqlFilename = checkDescription$SQL_FILE, 
        packageName = "DataQualityDashboard",
        cdmTableName = check["CDM_TABLE"],
        cdmFieldName = check["CDM_FIELD"],
        fkTableName = check["FK_TABLE"],
        fkFieldName = check["FK_FIELD"],
        fkDomain = check["FK_DOMAIN"],
        fkClass = check["FK_CLASS"],
        plausibleTemporalAfterTableName = check["PLAUSIBLE_TEMPORAL_AFTER_TABLE"],
        plausibleTemporalAfterFieldName = check["PLAUSIBLE_TEMPORAL_AFTER"],
        plausibleValueHigh = check["PLAUSIBLE_VALUE_HIGH"],
        plausibleValueLow = check["PLAUSIBLE_VALUE_LOW"],
        standardConceptFieldName = check["STANDARD_CONCEPT_FIELD_NAME"],
        cdmDatabaseSchema = cdmDatabaseSchema,
        warnOnMissingParameters = FALSE
      )
      
      if (sqlOnly) {
        write(x = sql, file = file.path(outputFolder, 
                                        sprintf("%s.sql", checkDescription$CHECK_NAME)), append = TRUE)
        data.frame()
      } else {
        # need to capture the result status
        tryCatch(
          expr = .processCheck(connectionDetails = connectionDetails,
                               check = check, 
                               checkDescription = checkDescription, sql = sql,
                               outputFolder = outputFolder),
          warning = function(w) {
            ParallelLogger::logWarn(sprintf("[Level: %s] [Check: %s] [CDM Table: %s] [CDM Field: %s] %s", 
                                            checkDescription$CHECK_LEVEL,
                                            checkDescription$CHECK_NAME, check["CDM_TABLE"], check["CDM_FIELD"], w$message))
            .recordResult(check = check, checkDescription = checkDescription, sql = sql, warning = w$message)
          },
          error = function(e) {
            ParallelLogger::logError(sprintf("[Level: %s] [Check: %s] [CDM Table: %s] [CDM Field: %s] %s", 
                                             checkDescription$CHECK_LEVEL,
                                             checkDescription$CHECK_NAME, check["CDM_TABLE"], check["CDM_FIELD"], e$message))
            .recordResult(check = check, checkDescription = checkDescription, sql = sql, error = e$message)  
          }
        ) 
      }    
    })
    do.call("rbind", dfs)
  } else {
    ParallelLogger::logWarn(paste0("Warning: Evaluation resulted in no checks: ", filterExpression))
    data.frame()
  }
}

.summarizeResults <- function(connectionDetails,
                              cdmDatabaseSchema,
                              checkResults,
                              cdmSourceName,
                              outputFolder,
                              startTime) {
  
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))
  
  # capture metadata -----------------------------------------------------------------------
  sql <- SqlRender::render(sql = "select * from @cdmDatabaseSchema.cdm_source;",
                           cdmDatabaseSchema = cdmDatabaseSchema)
  sql <- SqlRender::translate(sql = sql, targetDialect = connectionDetails$dbms)
  cdmSourceData <- DatabaseConnector::querySql(connection = connection, sql = sql)
  
  # prepare output ------------------------------------------------------------------------
  metadata <- cdmSourceData
  
  countTotal <- nrow(checkResults)
  countFailed <- nrow(checkResults[(!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS > 0) | !is.na(checkResults$ERROR),])
  
  # set a flag for when the check has failed
  checkResults[,"FAILED"] <- 0
  checkResults[(!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS > 0) | !is.na(checkResults$ERROR),"FAILED"]<- 1
  
  countThresholdFailure <- nrow(checkResults[(!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS>0),])
  countErrorFailure <- nrow(checkResults[!is.na(checkResults$ERROR),])
  countPassed <- countTotal - countFailed
  
  countTotalPlausibility = nrow(checkResults[checkResults$CATEGORY=='Plausibility',])
  countTotalConformance = nrow(checkResults[checkResults$CATEGORY=='Conformance',])
  countTotalCompleteness = nrow(checkResults[checkResults$CATEGORY=='Completeness',])
  countFailedPlausibility = nrow(checkResults[checkResults$CATEGORY=='Plausibility' & (!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS > 0 | !is.na(checkResults$ERROR)),])
  countFailedConformance = nrow(checkResults[checkResults$CATEGORY=='Conformance' & (!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS > 0 | !is.na(checkResults$ERROR)),])
  countFailedCompleteness = nrow(checkResults[checkResults$CATEGORY=='Completeness' & (!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS > 0 | !is.na(checkResults$ERROR)),])
  countPassedPlausibility = countTotalPlausibility - countFailedPlausibility
  countPassedConformance = countTotalConformance - countFailedConformance
  countPassedCompleteness = countTotalCompleteness - countFailedCompleteness
  
  overview <- list(
    countTotal = countTotal, 
    countPassed = countPassed, 
    countFailed = countFailed,
    percentPassed = round(countPassed / countTotal * 100),
    percentFailed = round(countFailed / countTotal * 100),
    countTotalPlausibility = countTotalPlausibility,
    countTotalConformance = countTotalConformance,
    countTotalCompleteness = countTotalCompleteness,
    countFailedPlausibility = countFailedPlausibility,
    countFailedConformance = countFailedConformance,
    countFailedCompleteness = countFailedCompleteness,
    countPassedPlausibility = countPassedPlausibility,
    countPassedConformance = countPassedConformance,
    countPassedCompleteness = countPassedCompleteness
  )
  
  endTime <- Sys.time()
  delta <- endTime - startTime
  
  result <- list(startTimestamp = startTime, 
                 endTimestamp = endTime,
                 executionTime = sprintf("%f %s", delta, attr(delta, "units")),
                 CheckResults = checkResults, 
                 Metadata = metadata, 
                 Overview = overview)
  
  resultJson <- jsonlite::toJSON(result)
  
  # TODO - add timestamp to result file output?
  write(resultJson, file.path(outputFolder, sprintf("results_%s.json", cdmSourceName)))
  
  result
}


#' Execute DQ checks
#' 
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param jsonFilePath              Path to the JSON results file generated using the execute function
#' 
#' @export
writeJsonResultsToTable <- function(connectionDetails,
                                    resultsDatabaseSchema,
                                    jsonFilePath) {
  
  jsonData <- jsonlite::read_json(jsonFilePath)
  checkResults <- lapply(jsonData$CheckResults, function(cr) {
    cr[sapply(cr, is.null)] <- NA
    as.data.frame(cr)
  })
  library(plyr)
  df <- do.call("rbind.fill", checkResults)
  .writeResultsToTable(connectionDetails = connectionDetails,
                       resultsDatabaseSchema = resultsDatabaseSchema,
                       checkResults = df)
}

.writeResultsToTable <- function(connectionDetails,
                                 resultsDatabaseSchema,
                                 checkResults) {
  
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))
  tableName <- sprintf("%s.dqdashboard_results", resultsDatabaseSchema)

  ParallelLogger::logInfo(sprintf("Writing results to table %s", tableName))
  
  tryCatch(
    expr = {
      DatabaseConnector::insertTable(connection = connection, tableName = tableName, data = checkResults, 
                                   dropTableIfExists = TRUE, createTable = TRUE, tempTable = FALSE)
      ParallelLogger::logInfo("Finished writing table")
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("Writing table failed: %s", e$message))
    }
  )
}


