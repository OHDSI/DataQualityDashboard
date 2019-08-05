
.recordResult <- function(result = NULL, check, 
                          checkDescription, sql, 
                          warning = NA, error = NA) {
  if (is.null(result)) {
    result <- data.frame(
      NUM_VIOLATED_ROWS = NA,
      PCT_VIOLATED_ROWS = NA,
     # CHECK_ID = checkId,
      QUERY_TEXT = sql,
      CHECK_NAME = checkDescription$CHECK_NAME,
      CHECK_LEVEL = checkDescription$CHECK_LEVEL,
      CHECK_DESCRIPTION = SqlRender::render(checkDescription$CHECK_DESCRIPTION, CDM_FIELD = check["CDM_FIELD"], 
                                            CDM_TABLE = check["CDM_TABLE"], warnOnMissingParameters = FALSE),
      CDM_TABLE = check["CDM_TABLE"],
      CDM_FIELD = check["CDM_FIELD"],
      CATEGORY = checkDescription$KAHN_CATEGORY,
      SUBCATEGORY = checkDescription$KAHN_SUBCATEGORY,
      CONTEXT = checkDescription$KAHN_CONTEXT,
      WARNING = warning,
      ERROR = error
    )  
  } else {
    #result$CHECK_ID <- checkId
    result$QUERY_TEXT <- sql
    result$CHECK_NAME <- checkDescription$CHECK_NAME
    result$CHECK_LEVEL <- checkDescription$CHECK_LEVEL
    result$CHECK_DESCRIPTION = SqlRender::render(checkDescription$CHECK_DESCRIPTION, CDM_FIELD = check["CDM_FIELD"], 
                                                 CDM_TABLE = check["CDM_TABLE"], warnOnMissingParameters = FALSE)
    result$CDM_TABLE <- check["CDM_TABLE"]
    result$CDM_FIELD <- check["CDM_FIELD"]
    result$CATEGORY <- checkDescription$KAHN_CATEGORY
    result$SUBCATEGORY <- checkDescription$KAHN_SUBCATEGORY
    result$CONTEXT <- checkDescription$KAHN_CONTEXT
    result$WARNING <- warning
    result$ERROR <- error
  }
  result
  #checkResults <<- dplyr::bind_rows(checkResults,result)  
}

  .processCheck <- function(connectionDetails, check, checkDescription, sql) {
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))
  result <- DatabaseConnector::querySql(connection = connection, sql = sql)
  .recordResult(result, check, checkDescription, sql)
}

#' Execute DQ checks
#' 
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param cdmDatabaseSchema         The fully qualified database name of the CDM schema
#' @param numThreads                The number of concurrent threads to use to execute the queries
#' @param cdmSourceName             The name of the CDM data source
#' @param sqlOnly                   Should the SQLs be executed (FALSE) or just returned (TRUE)?
#' @param outputFolder              The folder to output logs and SQL files to
#' 
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    cdmSourceName,
                    numThreads = 1,
                    sqlOnly = FALSE,
                    outputFolder = "output") {
  
  outputFolder <- file.path(outputFolder, cdmSourceName)
  
  if (!dir.exists(outputFolder)) {
    dir.create(path = outputFolder, recursive = TRUE)
  }
  
  # Log execution -----------------------------------------------------------------------------------------------------------------
  ParallelLogger::clearLoggers()
  logFileName <- sprintf("log_DqDashboard_%s.txt", cdmSourceName)
  unlink(file.path(outputFolder, logFileName))
  
  
  appenders <- list(ParallelLogger::createConsoleAppender(),
                    ParallelLogger::createFileAppender(layout = ParallelLogger::layoutParallel, 
                                                       fileName = file.path(outputFolder, logFileName)))    

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
  
  checkDescriptionsDf <- checkDescriptionsDf[checkDescriptionsDf$CHECK_LEVEL=="FIELD" & checkDescriptionsDf$EVALUATION_FILTER != "",]
  checkDescriptions <- split(checkDescriptionsDf, seq(nrow(checkDescriptionsDf)))
  
  cluster <- ParallelLogger::makeCluster(numberOfThreads = numThreads, singleThreadToMain = TRUE)
  resultsList <- ParallelLogger::clusterApply(cluster = cluster, x = checkDescriptions,
                                              fun = .runCheck, fieldChecks,
                                              connectionDetails, cdmDatabaseSchema, 
                                              outputFolder, sqlOnly)
  ParallelLogger::stopCluster(cluster = cluster)
  
  if (!sqlOnly) {
    checkResults <- do.call("rbind", resultsList)
    checkResults$checkId <- seq.int(nrow(checkResults))
    
    .summarizeResults(connectionDetails = connectionDetails, 
                      cdmDatabaseSchema = cdmDatabaseSchema, 
                      checkResults = checkResults,
                      cdmSourceName = cdmSourceName, 
                      outputFolder = outputFolder,
                      startTime = startTime)
    ParallelLogger::logInfo("Execution Complete")  
  }
  
  ParallelLogger::unregisterLogger("DqDashboard")
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
                               checkDescription = checkDescription, sql = sql),
          warning = function(w) {
            .recordResult(check = check, checkDescription = checkDescription, sql = sql, warning = w$message)
          },
          error = function(e) {
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
  
  result <- list(startTimestamp = startTime, 
                 endTimestamp = Sys.time(),
                 executionTime = gsub(pattern = "Time difference of ", replacement = "", x = Sys.time() - startTime),
                 CheckResults = checkResults, 
                 Metadata = metadata, 
                 Overview = overview)
  
  resultJson <- jsonlite::toJSON(result)
  
  # TODO - add timestamp to result file output?
  write(resultJson, file.path(outputFolder, sprintf("results_%s.json", cdmSourceName)))
}


