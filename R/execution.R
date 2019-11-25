# @file execution.R
#
# Copyright 2019 Observational Health Data Sciences and Informatics
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

.recordResult <- function(result = NULL, check, 
                          checkDescription, sql, 
                          executionTime = NA,
                          warning = NA, error = NA) {
  
  columns <- lapply(names(check), function(c) {
    setNames(check[c], c)
  })

  params <- c(list(sql = checkDescription$checkDescription),
              list(warnOnMissingParameters = FALSE),
              unlist(columns, recursive = FALSE))
  
  reportResult <- data.frame(
    NUM_VIOLATED_ROWS = NA,
    PCT_VIOLATED_ROWS = NA,
    EXECUTION_TIME = executionTime,
    QUERY_TEXT = sql,
    CHECK_NAME = checkDescription$checkName,
    CHECK_LEVEL = checkDescription$checkLevel,
    CHECK_DESCRIPTION = do.call(SqlRender::render, params),
    CDM_TABLE_NAME = check["cdmTableName"],
    CDM_FIELD_NAME = check["cdmFieldName"],
    CONCEPT_ID = check["conceptId"],
    UNIT_CONCEPT_ID = check["unitConceptId"],
    SQL_FILE = checkDescription$sqlFile,
    CATEGORY = checkDescription$kahnCategory,
    SUBCATEGORY = checkDescription$kahnSubcategory,
    CONTEXT = checkDescription$kahnContext,
    WARNING = warning,
    ERROR = error, row.names = NULL, stringsAsFactors = FALSE
  )
  
  if (!is.null(result)) {
    reportResult$NUM_VIOLATED_ROWS <- result$NUM_VIOLATED_ROWS
    reportResult$PCT_VIOLATED_ROWS <- result$PCT_VIOLATED_ROWS
  }
  reportResult
}

.processCheck <- function(connection,
                          connectionDetails, 
                          check, 
                          checkDescription, 
                          sql, 
                          outputFolder) {
  singleThreaded <- TRUE
  start <- Sys.time()
  if (is.null(connection)) {
    singleThreaded <- FALSE
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    on.exit(DatabaseConnector::disconnect(connection = connection))  
  }
  
  errorReportFile <- file.path(outputFolder, "errors", 
                               sprintf("%s_%s_%s_%s.txt",
                                       checkDescription$checkLevel,
                                       checkDescription$checkName,
                                       check["cdmTableName"],
                                       check["cdmFieldName"]))  
  tryCatch(
    expr = {
      if (singleThreaded) {
        if (.needsAutoCommit(connection)) {
          rJava::.jcall(connection@jConnection, "V", "setAutoCommit", TRUE)
        }  
      }
      
      result <- DatabaseConnector::querySql(connection = connection, sql = sql, 
                                            errorReportFile = errorReportFile)
      
      delta <- difftime(Sys.time(), start, units = "secs")
      .recordResult(result = result, check = check, checkDescription = checkDescription, sql = sql,  
                    executionTime = sprintf("%f %s", delta, attr(delta, "units")))
    },
    warning = function(w) {
      ParallelLogger::logWarn(sprintf("[Level: %s] [Check: %s] [CDM Table: %s] [CDM Field: %s] %s", 
                                      checkDescription$checkLevel,
                                      checkDescription$checkName, 
                                      check["cdmTableName"], 
                                      check["cdmFieldName"], w$message))
      .recordResult(check = check, checkDescription = checkDescription, sql = sql, warning = w$message)
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("[Level: %s] [Check: %s] [CDM Table: %s] [CDM Field: %s] %s", 
                                       checkDescription$checkLevel,
                                       checkDescription$checkName, 
                                       check["cdmTableName"], 
                                       check["cdmFieldName"], e$message))
      .recordResult(check = check, checkDescription = checkDescription, sql = sql, error = e$message)  
    }
  ) 
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
#' @param checkLevels               Choose which DQ check levels to execute. Default is all 3 (TABLE, FIELD, CONCEPT)
#' @param checkNames                (OPTIONAL) Choose which check names to execute. Names can be found in inst/csv/OMOP_CDM_v[cdmVersion]_Check_Desciptions.csv
#' @param tablesToExclude           (OPTIONAL) Choose which CDM tables to exclude from the execution.
#' 
#' @return If sqlOnly = FALSE, a list object of results
#' 
#' @export
executeDqChecks <- function(connectionDetails,
                            cdmDatabaseSchema,
                            resultsDatabaseSchema,
                            cdmSourceName,
                            numThreads = 1,
                            sqlOnly = FALSE,
                            outputFolder = "output",
                            verboseMode = FALSE,
                            writeToTable = TRUE,
                            checkLevels = c("TABLE", "FIELD", "CONCEPT"),
                            checkNames = c(),
                            tablesToExclude = c(),
                            cdmVersion = "5.3.1") {
  
  options(scipen = 999)
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
  
  checkDescriptionsDf <- read.csv(system.file("csv", sprintf("OMOP_CDMv%s_Check_Descriptions.csv", cdmVersion), 
                                            package = "DataQualityDashboard"), 
                                stringsAsFactors = FALSE)
  tableChecks <- read.csv(system.file("csv", sprintf("OMOP_CDMv%s_Table_Level.csv", cdmVersion),
                                      package = "DataQualityDashboard"), 
                          stringsAsFactors = FALSE)
  fieldChecks <- read.csv(system.file("csv", sprintf("OMOP_CDMv%s_Field_Level.csv", cdmVersion),
                                      package = "DataQualityDashboard"), 
                          stringsAsFactors = FALSE)
  conceptChecks <- read.csv(system.file("csv", sprintf("OMOP_CDMv%s_Concept_Level.csv", cdmVersion),
                                      package = "DataQualityDashboard"), 
                          stringsAsFactors = FALSE)
  
  # ensure we use only checks that are intended to be run -----------------------------------------
  
  if (length(tablesToExclude) > 0) {
    tablesToExclude <- toupper(tablesToExclude)
    ParallelLogger::logInfo(sprintf("CDM Tables skipped: %s", paste(tablesToExclude, collapse = ", ")))
    tableChecks <- tableChecks[!tableChecks$cdmTableName %in% tablesToExclude,]
    fieldChecks <- fieldChecks[!fieldChecks$cdmTableName %in% tablesToExclude,]
    conceptChecks <- conceptChecks[!conceptChecks$cdmTableName %in% tablesToExclude,]
  }
  
  library(magrittr)
  tableChecks <- tableChecks %>% dplyr::select_if(function(x) !(all(is.na(x)) | all(x=="")))
  fieldChecks <- fieldChecks %>% dplyr::select_if(function(x) !(all(is.na(x)) | all(x=="")))
  conceptChecks <- conceptChecks %>% dplyr::select_if(function(x) !(all(is.na(x)) | all(x=="")))

  
  checksToInclude <- checkDescriptionsDf$checkName[sapply(checkDescriptionsDf$checkName, function(check) {
    !is.null(eval(parse(text = sprintf("tableChecks$%s", check)))) |
      !is.null(eval(parse(text = sprintf("fieldChecks$%s", check)))) |
      !is.null(eval(parse(text = sprintf("conceptChecks$%s", check))))
  })]
  
  checkDescriptionsDf <- checkDescriptionsDf[checkDescriptionsDf$checkLevel %in% checkLevels & 
                                               checkDescriptionsDf$evaluationFilter != "" &
                                               checkDescriptionsDf$sqlFile != "" &
                                               checkDescriptionsDf$checkName %in% checksToInclude, ]
  
  if (length(checkNames) > 0) {
    checkDescriptionsDf <- checkDescriptionsDf[checkDescriptionsDf$checkName %in% checkNames,]
  }
  
  if (nrow(checkDescriptionsDf) == 0) {
    stop("No checks are available based on excluded tables. Please review tablesToExclude.")
  }
  
  checkDescriptions <- split(checkDescriptionsDf, seq(nrow(checkDescriptionsDf)))
  
  connection <- NULL
  if (numThreads == 1) {
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  }
  
  cluster <- ParallelLogger::makeCluster(numberOfThreads = numThreads, singleThreadToMain = TRUE)
  resultsList <- ParallelLogger::clusterApply(cluster = cluster, x = checkDescriptions,
                                              fun = .runCheck, 
                                              tableChecks,
                                              fieldChecks,
                                              conceptChecks,
                                              connectionDetails, 
                                              connection,
                                              cdmDatabaseSchema, 
                                              outputFolder, sqlOnly)
  ParallelLogger::stopCluster(cluster = cluster)
  
  if (numThreads == 1) {
    DatabaseConnector::disconnect(connection = connection)
  }
  
  allResults <- NULL
  if (!sqlOnly) {
    checkResults <- do.call(rbind, resultsList)
    checkResults$checkId <- seq.int(nrow(checkResults))
    
    allResults <- .summarizeResults(connectionDetails = connectionDetails, 
                      cdmDatabaseSchema = cdmDatabaseSchema, 
                      checkResults = checkResults,
                      cdmSourceName = cdmSourceName, 
                      outputFolder = outputFolder,
                      startTime = startTime,
                      tableChecks = tableChecks, 
                      fieldChecks = fieldChecks,
                      conceptChecks = conceptChecks)
    
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
                      tableChecks,
                      fieldChecks,
                      conceptChecks,
                      connectionDetails,
                      connection,
                      cdmDatabaseSchema, 
                      outputFolder, 
                      sqlOnly) {
  
  library(magrittr)
  ParallelLogger::logInfo(sprintf("Processing check description: %s", checkDescription$checkName))
  
  filterExpression <- sprintf("%sChecks %%>%% dplyr::filter(%s)",
                              tolower(checkDescription$checkLevel),
                              checkDescription$evaluationFilter)
  checks <- eval(parse(text = filterExpression))
  
  if (sqlOnly) {
    unlink(file.path(outputFolder, sprintf("%s.sql", checkDescription$checkName)))
  }
  
  if (nrow(checks) > 0) {
    dfs <- apply(X = checks, MARGIN = 1, function(check) {
      
      columns <- lapply(names(check), function(c) {
        setNames(check[c], c)
      })

      params <- c(list(dbms = connectionDetails$dbms),
                  list(sqlFilename = checkDescription$sqlFile),
                  list(packageName = "DataQualityDashboard"),
                  list(warnOnMissingParameters = FALSE),
                  list(cdmDatabaseSchema = cdmDatabaseSchema),
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

.evaluateThresholds <- function(checkResults,
                                tableChecks,
                                fieldChecks,
                                conceptChecks) {
  
  checkResults$FAILED <- 0
  checkResults$THRESHOLD_VALUE <- NA
  
  for (i in 1:nrow(checkResults)) {
    thresholdField <- sprintf("%sThreshold", checkResults[i,]$CHECK_NAME)
    
    # find if field exists -----------------------------------------------
    thresholdFieldExists <- eval(parse(text = 
                                         sprintf("'%s' %%in%% colnames(%sChecks)", 
                                                 thresholdField, 
                                                 tolower(checkResults[i,]$CHECK_LEVEL))))
    
    if (!thresholdFieldExists) {
      thresholdValue <- NA
    } else {
      if (checkResults[i,]$CHECK_LEVEL == "TABLE") {
        
        thresholdFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                                   thresholdField, checkResults[i,]$CDM_TABLE_NAME)
        
      } else if (checkResults[i,]$CHECK_LEVEL == "FIELD") {
        
        thresholdFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
                                   thresholdField, 
                                   checkResults[i,]$CDM_TABLE_NAME,
                                   checkResults[i,]$CDM_FIELD_NAME)
        
        
      } else if (checkResults[i,]$CHECK_LEVEL == "CONCEPT") {
        
        if (is.na(checkResults[i,]$UNIT_CONCEPT_ID)) {
          
          thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s]",
                                     thresholdField, 
                                     checkResults[i,]$CDM_TABLE_NAME,
                                     checkResults[i,]$CDM_FIELD_NAME,
                                     checkResults[i,]$CONCEPT_ID)
        } else {
          
          thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
                                     thresholdField, 
                                     checkResults[i,]$CDM_TABLE_NAME,
                                     checkResults[i,]$CDM_FIELD_NAME,
                                     checkResults[i,]$CONCEPT_ID,
                                     checkResults[i,]$UNIT_CONCEPT_ID)
          } 
      }
      
      thresholdValue <- eval(parse(text = thresholdFilter))
      checkResults[i,]$THRESHOLD_VALUE <- thresholdValue
    }

    if (!is.na(checkResults[i,]$ERROR)) {
      checkResults[i,]$FAILED <- 1
    } else if (is.na(thresholdValue)) {
      if (!is.na(checkResults[i,]$NUM_VIOLATED_ROWS) & checkResults[i,]$NUM_VIOLATED_ROWS > 0) {
        checkResults[i,]$FAILED <- 1
      }
    } else if (checkResults[i,]$PCT_VIOLATED_ROWS * 100 > thresholdValue) {
        checkResults[i,]$FAILED <- 1  
    }  
  }
  
  checkResults
}

.summarizeResults <- function(connectionDetails,
                              cdmDatabaseSchema,
                              checkResults,
                              cdmSourceName,
                              outputFolder,
                              startTime,
                              tableChecks,
                              fieldChecks,
                              conceptChecks) {
  
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))
  
  # capture metadata -----------------------------------------------------------------------
  sql <- SqlRender::render(sql = "select * from @cdmDatabaseSchema.cdm_source;",
                           cdmDatabaseSchema = cdmDatabaseSchema)
  sql <- SqlRender::translate(sql = sql, targetDialect = connectionDetails$dbms)
  cdmSourceData <- DatabaseConnector::querySql(connection = connection, sql = sql)
  
  # prepare output ------------------------------------------------------------------------
  metadata <- cdmSourceData
  
  # evaluate thresholds-------------------------------------------------------------------
  
  checkResults <- .evaluateThresholds(checkResults = checkResults, 
                                      tableChecks = tableChecks, 
                                      fieldChecks = fieldChecks,
                                      conceptChecks = conceptChecks)
  
  countTotal <- nrow(checkResults)
  countThresholdFailed <- nrow(checkResults[checkResults$FAILED == 1 & 
                                               is.na(checkResults$ERROR),])
  countErrorFailed <- nrow(checkResults[!is.na(checkResults$ERROR),])
  countOverallFailed <- nrow(checkResults[checkResults$FAILED == 1,])
  
  countPassed <- countTotal - countOverallFailed
  
  countTotalPlausibility <- nrow(checkResults[checkResults$CATEGORY=='Plausibility',])
  countTotalConformance <- nrow(checkResults[checkResults$CATEGORY=='Conformance',])
  countTotalCompleteness <- nrow(checkResults[checkResults$CATEGORY=='Completeness',])
  
  countFailedPlausibility <- nrow(checkResults[checkResults$CATEGORY=='Plausibility' & 
                                                 checkResults$FAILED == 1,])
  
  countFailedConformance <- nrow(checkResults[checkResults$CATEGORY=='Conformance' &
                                                checkResults$FAILED == 1,])
  
  countFailedCompleteness <- nrow(checkResults[checkResults$CATEGORY=='Completeness' &
                                                 checkResults$FAILED == 1,])
  
  countPassedPlausibility <- countTotalPlausibility - countFailedPlausibility
  countPassedConformance <- countTotalConformance - countFailedConformance
  countPassedCompleteness <- countTotalCompleteness - countFailedCompleteness
  
  overview <- list(
    countTotal = countTotal, 
    countPassed = countPassed, 
    countErrorFailed = countErrorFailed,
    countThresholdFailed = countThresholdFailed,
    countOverallFailed = countOverallFailed,
    percentPassed = round(countPassed / countTotal * 100),
    percentFailed = round(countOverallFailed / countTotal * 100),
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
                 executionTime = sprintf("%.0f %s", delta, attr(delta, "units")),
                 CheckResults = checkResults, 
                 Metadata = metadata, 
                 Overview = overview)
  
  resultJson <- jsonlite::toJSON(result)
  write(resultJson, file.path(outputFolder, sprintf("results_%s.json", cdmSourceName)))
  
  result
}


#' Write JSON Results to SQL Table
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
  
  df <- do.call(plyr::rbind.fill, checkResults)
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

.needsAutoCommit <- function(connection) {
  autoCommit <- FALSE
  if (!is.null(connection)) {
    if (inherits(connection, "DatabaseConnectorJdbcConnection")) {
      if (connectionDetails$dbms %in% c("postgresql", "redshift")) {
        autoCommit <- TRUE
      }
    }
  }
  autoCommit
}
