# @file execution.R
#
# Copyright 2020 Observational Health Data Sciences and Informatics
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

ABORT_MESSAGE <- "Process was aborted by User"

#' @importFrom stats na.omit
.getCheckId <- function(checkLevel, checkName, cdmTableName,
                        cdmFieldName = NA, conceptId = NA,
                        unitConceptId = NA) {
  tolower(
    paste(
      na.omit(c(
        dplyr::na_if(gsub(" ", "", checkLevel), ""),
        dplyr::na_if(gsub(" ", "", checkName), ""),
        dplyr::na_if(gsub(" ", "", cdmTableName), ""),
        dplyr::na_if(gsub(" ", "", cdmFieldName), ""),
        dplyr::na_if(gsub(" ", "", conceptId), ""),
        dplyr::na_if(gsub(" ", "", unitConceptId), "")
      )),
      collapse = "_"
    )
  )
}

#' @importFrom stats setNames
.recordResult <- function(result = NULL, check,
                          checkDescription, sql, 
                          executionTime = NA,
                          warning = NA, error = NA) {
  
  columns <- lapply(names(check), function(c) {
    setNames(check[c], c)
  })
  
  params <- c(list(sql = checkDescription$checkDescription),
              list(warnOnMissingParameters = FALSE),
              lapply(unlist(columns, recursive = FALSE), toupper))
  
  reportResult <- data.frame(
    NUM_VIOLATED_ROWS = NA,
    PCT_VIOLATED_ROWS = NA,
    NUM_DENOMINATOR_ROWS = NA,
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
    ERROR = error,
    checkId = .getCheckId(checkDescription$checkLevel, checkDescription$checkName, check["cdmTableName"], check["cdmFieldName"], check["conceptId"], check["unitConceptId"]),
    row.names = NULL, stringsAsFactors = FALSE
  )
  
  if (!is.null(result)) {
    reportResult$NUM_VIOLATED_ROWS <- result$NUM_VIOLATED_ROWS
    reportResult$PCT_VIOLATED_ROWS <- result$PCT_VIOLATED_ROWS
    reportResult$NUM_DENOMINATOR_ROWS <- result$NUM_DENOMINATOR_ROWS
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
      if (singleThreaded &&
          !is.null(connection) &&
          inherits(connection, "DatabaseConnectorJdbcConnection") &&
          connectionDetails$dbms %in% c("postgresql", "redshift")) {

        rJava::.jcall(connection@jConnection, "V", "setAutoCommit", TRUE)
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
      ParallelLogger::logError(sprintf("#DQD [Level: %s] [Check: %s] [CDM Table: %s] [CDM Field: %s] %s",
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
#' @param vocabDatabaseSchema       The fully qualified database name of the vocabulary schema (default is to set it as the cdmDatabaseSchema)
#' @param numThreads                The number of concurrent threads to use to execute the queries
#' @param cdmSourceName             The name of the CDM data source
#' @param sqlOnly                   Should the SQLs be executed (FALSE) or just returned (TRUE)?
#' @param outputFolder              The folder to output logs and SQL files to
#' @param outputFile                (OPTIONAL) File to write results JSON object
#' @param verboseMode               Boolean to determine if the console will show all execution steps. Default = FALSE
#' @param writeToTable              Boolean to indicate if the check results will be written to the dqdashboard_results table
#' @param writeToCsv                Boolean to indicate if the check results will be written to a csv file
#' @param csvFile                   (OPTIONAL) CSV file to write results
#'                                  in the resultsDatabaseSchema. Default is TRUE.
#' @param writeTableName The name of the results table. Defaults to `dqdashboard_results`.
#' @param checkLevels               Choose which DQ check levels to execute. Default is all 3 (TABLE, FIELD, CONCEPT)
#' @param checkNames                (OPTIONAL) Choose which check names to execute. Names can be found in inst/csv/OMOP_CDM_v[cdmVersion]_Check_Desciptions.csv. Note that "cdmTable", "cdmField" and "measureValueCompleteness" are always executed.
#' @param cohortDefinitionId        The cohort definition id for the cohort you wish to run the DQD on. The package assumes a standard OHDSI cohort table called 'Cohort' 
#'                                  with the fields cohort_definition_id and subject_id.
#' @param cohortDatabaseSchema      The schema where the cohort table is located.
#' @param tablesToExclude           (OPTIONAL) Choose which CDM tables to exclude from the execution.
#' @param cdmVersion                The CDM version to target for the data source. By default, 5.3.1 is used.
#' @param tableCheckThresholdLoc    The location of the threshold file for evaluating the table checks. If not specified the default thresholds will be applied.
#' @param fieldCheckThresholdLoc    The location of the threshold file for evaluating the field checks. If not specified the default thresholds will be applied.
#' @param conceptCheckThresholdLoc  The location of the threshold file for evaluating the concept checks. If not specified the default thresholds will be applied.
#' 
#' @return If sqlOnly = FALSE, a list object of results
#' 
#' @importFrom magrittr %>%
#' @import DatabaseConnector
#' @importFrom utils packageVersion read.csv
#' @export
executeDqChecks <- function(connectionDetails,
                            cdmDatabaseSchema,
                            resultsDatabaseSchema,
                            vocabDatabaseSchema = cdmDatabaseSchema,
                            cdmSourceName,
                            numThreads = 1,
                            sqlOnly = FALSE,
                            outputFolder = "output",
                            outputFile = "",
                            verboseMode = FALSE,
                            writeToTable = TRUE,
                            writeTableName = "dqdashboard_results",
                            writeToCsv = FALSE,
                            csvFile = "",
                            checkLevels = c("TABLE", "FIELD", "CONCEPT"),
                            checkNames = c(),
                            cohortDefinitionId = c(),
                            cohortDatabaseSchema = resultsDatabaseSchema,
                            tablesToExclude = c("CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN"),
                            cdmVersion = "5.3.1",
                            tableCheckThresholdLoc = "default",
                            fieldCheckThresholdLoc = "default",
                            conceptCheckThresholdLoc = "default",
                            dbLogger,
                            interruptor) {
  # Check is aborted -----------
  if (interruptor$isAborted()) {
    print(ABORT_MESSAGE)
    stop(ABORT_MESSAGE)
  }

  # Check input -------------------------------------------------------------------------------------------------------------------
  if (!("connectionDetails" %in% class(connectionDetails))){
    stop("connectionDetails must be an object of class 'connectionDetails'.")
  }

  stopifnot(is.character(cdmDatabaseSchema), is.character(resultsDatabaseSchema), is.numeric(numThreads))
  stopifnot(is.character(cdmSourceName), is.logical(sqlOnly), is.character(outputFolder), is.logical(verboseMode))
  stopifnot(is.logical(writeToTable), is.character(checkLevels))

  if (!all(checkLevels %in% c("TABLE", "FIELD", "CONCEPT"))) {
    stop('checkLevels argument must be a subset of c("TABLE", "FIELD", "CONCEPT").
         You passed in ', paste(checkLevels, collapse = ", "))
  }

  stopifnot(is.null(checkNames) | is.character(checkNames), is.null(tablesToExclude) | is.character(tablesToExclude))
  stopifnot(is.character(cdmVersion))
  
  # Warning if check names for determining NA is missing
  if (!length(checkNames)==0){
    for(requiredCheckName in c("cdmTable", "cdmField", "measureValueCompleteness")) {
      if (!(requiredCheckName %in% checkNames)) {
        warning(paste(requiredCheckName, "is missing from the provided checkNames. The NA status will not be calculated correctly."))
      }
    }
  }

  # Use UTF-8 encoding to address issue: "special characters in metadata #33"
  saveEncoding <- getOption("encoding")
  options("encoding" = "UTF-8")

  # Setup output folder ------------------------------------------------------------------------------------------------------------
  options(scipen = 999)

  # capture metadata -----------------------------------------------------------------------
  if (!sqlOnly) {
    print("Connecting to CDM database...")
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    print("Successfully connected to CDM database!")
    sql <- SqlRender::render(sql = "select * from @cdmDatabaseSchema.cdm_source;",
                           cdmDatabaseSchema = cdmDatabaseSchema)
    sql <- SqlRender::translate(sql = sql, targetDialect = connectionDetails$dbms)
    metadata <- DatabaseConnector::querySql(connection = connection, sql = sql)
    if (nrow(metadata)<1) {
      stop("Please populate the cdm_source table before executing data quality checks.")
    }
    metadata$DQD_VERSION <- as.character(packageVersion("DataQualityDashboard"))
    DatabaseConnector::disconnect(connection)
  } else {
    metadata <- NA
  }

  outputFolder <- file.path(outputFolder, tolower(metadata$CDM_SOURCE_ABBREVIATION))
  
  if (!dir.exists(outputFolder)) {
    dir.create(path = outputFolder, recursive = TRUE)
  }
  
  if (dir.exists(file.path(outputFolder, "errors"))) {
    unlink(file.path(outputFolder, "errors"), recursive = TRUE)
  }
  
  dir.create(file.path(outputFolder, "errors"), recursive = TRUE)
  
  # Log execution -----------------------------------------------------------------------------------------------------------------
  ParallelLogger::clearLoggers()

  appenders <- list(createDqdLogAppender(dbLogger))
  parallelLogger <- ParallelLogger::createLogger(name = "DqdDashboard", threshold = "INFO", appenders = appenders)
  ParallelLogger::registerLogger(parallelLogger)

  ParallelLogger::logInfo("#DQD Execution started")

  # load CSVs ----------------------------------------------------------------------------------------
  
  startTime <- Sys.time()
  
  checkDescriptionsDf <- read.csv(system.file("csv", sprintf("OMOP_CDMv%s_Check_Descriptions.csv", cdmVersion), 
                                              package = "DataQualityDashboard"),
                                  stringsAsFactors = FALSE)


  if (tableCheckThresholdLoc == "default"){
    tableChecks <- read.csv(system.file("csv", sprintf("OMOP_CDMv%s_Table_Level.csv", cdmVersion),
                                        package = "DataQualityDashboard"),
                            stringsAsFactors = FALSE, na.strings = c(" ",""))} else {tableChecks <- read.csv(tableCheckThresholdLoc,
                                                                                                             stringsAsFactors = FALSE, na.strings = c(" ",""))}

  if (fieldCheckThresholdLoc == "default"){
    fieldChecks <- read.csv(system.file("csv", sprintf("OMOP_CDMv%s_Field_Level.csv", cdmVersion),
                                        package = "DataQualityDashboard"),
                            stringsAsFactors = FALSE, na.strings = c(" ",""))} else {fieldChecks <- read.csv(fieldCheckThresholdLoc,
                                                                                                             stringsAsFactors = FALSE, na.strings = c(" ",""))}

  if (conceptCheckThresholdLoc == "default"){
    conceptChecks <- read.csv(system.file("csv", sprintf("OMOP_CDMv%s_Concept_Level.csv", cdmVersion),
                                          package = "DataQualityDashboard"),
                              stringsAsFactors = FALSE, na.strings = c(" ",""))} else {conceptChecks <- read.csv(conceptCheckThresholdLoc,
                                                                                                                 stringsAsFactors = FALSE, na.strings = c(" ",""))}
  
  # ensure we use only checks that are intended to be run -----------------------------------------
  
  if (length(tablesToExclude) > 0) {
    tablesToExclude <- toupper(tablesToExclude)
    ParallelLogger::logInfo(sprintf("#DQD CDM Tables skipped: %s", paste(tablesToExclude, collapse = ", ")))
    tableChecks <- tableChecks[!tableChecks$cdmTableName %in% tablesToExclude,]
    fieldChecks <- fieldChecks[!fieldChecks$cdmTableName %in% tablesToExclude &
                                 !fieldChecks$fkTableName %in% tablesToExclude &
                                 !fieldChecks$plausibleTemporalAfterTableName %in% tablesToExclude,]
    conceptChecks <- conceptChecks[!conceptChecks$cdmTableName %in% tablesToExclude,]
  }
  
  ## remove offset from being checked
  fieldChecks <- subset(fieldChecks, cdmFieldName != '"offset"')

  # tableChecks <- tableChecks %>% dplyr::select_if(function(x) !(all(is.na(x)) | all(x=="")))
  # fieldChecks <- fieldChecks %>% dplyr::select_if(function(x) !(all(is.na(x)) | all(x=="")))
  # conceptChecks <- conceptChecks %>% dplyr::select_if(function(x) !(all(is.na(x)) | all(x=="")))

  
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
  if (numThreads == 1 & !sqlOnly) {
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  }
  
  fieldChecks$cdmFieldName <- toupper(fieldChecks$cdmFieldName)
  conceptChecks$cdmFieldName <- toupper(conceptChecks$cdmFieldName)

  cluster <- ParallelLogger::makeCluster(numberOfThreads = numThreads, singleThreadToMain = TRUE)
  resultsList <- ParallelLogger::clusterApply(
    cluster = cluster,
    x = checkDescriptions,
    fun = .runCheck,
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
    sqlOnly,
    progressBar = TRUE,
    dbLogger,
    interruptor
  )
  ParallelLogger::stopCluster(cluster = cluster)
  
  if (numThreads == 1 & !sqlOnly) {
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
                                    outputFile = outputFile,
                                    startTime = startTime,
                                    tableChecks = tableChecks, 
                                    fieldChecks = fieldChecks,
                                    conceptChecks = conceptChecks,
                                    metadata = metadata)

    ParallelLogger::logInfo("#DQD Execution Completed")
  }

  
  # write to table ----------------------------------------------------------------------
  
  if (!sqlOnly & writeToTable) {
    .writeResultsToTable(connectionDetails = connectionDetails,
                         resultsDatabaseSchema = resultsDatabaseSchema,
                         checkResults = allResults$CheckResults,
                         writeTableName = writeTableName,
                         cohortDefinitionId = cohortDefinitionId)
  }
  
  # write to CSV ----------------------------------------------------------------------

  if (!sqlOnly & writeToCsv) {
    if (nchar(csvFile)==0)  {
      csvFile <- sprintf("%s.csv", sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(allResults$outputFile)))
    }
    .writeResultsToCsv(checkResults = allResults$CheckResults,
                       csvPath = file.path(outputFolder, csvFile))
  }

  if (sqlOnly) {
    invisible(allResults)
  } else {
    allResults  
  }

  ParallelLogger::unregisterLogger("DqDashboard")
  
  # Reset encoding to previous value
  options("encoding" = saveEncoding)

  return(allResults)
}

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
                      sqlOnly,
                      dbLogger,
                      interruptor) {
  if (interruptor$isAborted()) {
    print(ABORT_MESSAGE)
    stop(ABORT_MESSAGE)
  }

  ParallelLogger::logInfo(sprintf("#DQD Processing check description: %s", checkDescription$checkName))
  
  filterExpression <- sprintf("%sChecks %%>%% dplyr::filter(%s)",
                              tolower(checkDescription$checkLevel),
                              checkDescription$evaluationFilter)
  checks <- eval(parse(text = filterExpression))
  
  cohort <- (!is.null(cohortDefinitionId) && length(cohortDefinitionId > 0))
  
  if (sqlOnly) {
    unlink(file.path(outputFolder, sprintf("%s.sql", checkDescription$checkName)))
  }
  
  if (nrow(checks) > 0) {
    dfs <- apply(X = checks, MARGIN = 1, function(check) {
      
      params <- c(warnOnMissingParameters = FALSE,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortDefinitionId = cohortDefinitionId,
                  vocabDatabaseSchema = vocabDatabaseSchema,
                  cohort = cohort,
                  checks)
      
      path <- file.path("sql", "sql_server", checkDescription$sqlFile)
      sql <- SqlRender::readSql(system.file(path, package = "DataQualityDashboard", mustWork = TRUE))
      sql <- do.call(SqlRender::render, as.list(c(sql = sql, params)))
      sql <- SqlRender::translate(sql, connectionDetails$dbms)
      
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
    ParallelLogger::logWarn(paste0("#DQD Warning: Evaluation resulted in no checks: ", filterExpression))
    data.frame()
  }
}


.evaluateThresholds <- function(checkResults,
                                tableChecks,
                                fieldChecks,
                                conceptChecks) {
  
  checkResults$FAILED <- 0
  checkResults$PASSED <- 0
  checkResults$IS_ERROR <- 0
  checkResults$NOT_APPLICABLE <- 0
  checkResults$NOT_APPLICABLE_REASON <- NA
  checkResults$THRESHOLD_VALUE <- NA
  checkResults$NOTES_VALUE <- NA
  
  for (i in 1:nrow(checkResults)) {
    thresholdField <- sprintf("%sThreshold", checkResults[i,]$CHECK_NAME)
    notesField <- sprintf("%sNotes", checkResults[i,]$CHECK_NAME)
    
    # find if field exists -----------------------------------------------
    thresholdFieldExists <- eval(parse(text = 
                                         sprintf("'%s' %%in%% colnames(%sChecks)", 
                                                 thresholdField, 
                                                 tolower(checkResults[i,]$CHECK_LEVEL))))
    
    if (!thresholdFieldExists) {
      thresholdValue <- NA
      notesValue <- NA
    } else {
      if (checkResults[i,]$CHECK_LEVEL == "TABLE") {
        
        thresholdFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                                   thresholdField, checkResults[i,]$CDM_TABLE_NAME)
        notesFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                               notesField, checkResults[i,]$CDM_TABLE_NAME)
        
      } else if (checkResults[i,]$CHECK_LEVEL == "FIELD") {
        
        thresholdFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
                                   thresholdField, 
                                   checkResults[i,]$CDM_TABLE_NAME,
                                   checkResults[i,]$CDM_FIELD_NAME)
        notesFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
                               notesField,
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
          notesFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s]",
                                 notesField,
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
                                     as.integer(checkResults[i,]$UNIT_CONCEPT_ID))
          notesFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
                                 notesField,
                                 checkResults[i,]$CDM_TABLE_NAME,
                                 checkResults[i,]$CDM_FIELD_NAME,
                                 checkResults[i,]$CONCEPT_ID,
                                 as.integer(checkResults[i,]$UNIT_CONCEPT_ID))
        } 
      }
      
      thresholdValue <- eval(parse(text = thresholdFilter))
      notesValue <- eval(parse(text = notesFilter))
      
      checkResults[i,]$THRESHOLD_VALUE <- thresholdValue
      checkResults[i,]$NOTES_VALUE <- notesValue
    }
    
    if (!is.na(checkResults[i,]$ERROR)) {
      checkResults[i,]$IS_ERROR <- 1
    } else if (is.na(thresholdValue) | thresholdValue == 0) {
      # If no threshold, or threshold is 0%, then any violating records will cause this check to fail
      if (!is.na(checkResults[i,]$NUM_VIOLATED_ROWS) & checkResults[i,]$NUM_VIOLATED_ROWS > 0) {
        checkResults[i,]$FAILED <- 1
      }
    } else if (checkResults[i,]$PCT_VIOLATED_ROWS * 100 > thresholdValue) {
      checkResults[i,]$FAILED <- 1  
    }
  }
  
  missingTables <- dplyr::select(
    dplyr::filter(checkResults, CHECK_NAME == "cdmTable" & FAILED == 1),
    CDM_TABLE_NAME)
  if (nrow(missingTables) > 0) {
    missingTables$TABLE_IS_MISSING <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, missingTables, by = "CDM_TABLE_NAME"),
      TABLE_IS_MISSING = ifelse(CHECK_NAME != "cdmTable" & IS_ERROR == 0, TABLE_IS_MISSING, NA))
  } else {
    checkResults$TABLE_IS_MISSING <- NA
  }

  missingFields <- dplyr::select(
    dplyr::filter(checkResults, CHECK_NAME == "cdmField" & FAILED == 1 & is.na(TABLE_IS_MISSING)),
    CDM_TABLE_NAME, CDM_FIELD_NAME)
  if (nrow(missingFields) > 0) {
    missingFields$FIELD_IS_MISSING <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, missingFields, by = c("CDM_TABLE_NAME", "CDM_FIELD_NAME")),
      FIELD_IS_MISSING = ifelse(CHECK_NAME != "cdmField" & IS_ERROR == 0, FIELD_IS_MISSING, NA))
  } else {
    checkResults$FIELD_IS_MISSING <- NA
  }

  emptyTables <- dplyr::distinct(
    dplyr::select(
      dplyr::filter(checkResults, CHECK_NAME == "measureValueCompleteness" &
                      NUM_DENOMINATOR_ROWS == 0 &
                      IS_ERROR == 0 &
                      is.na(TABLE_IS_MISSING) &
                      is.na(FIELD_IS_MISSING)),
      CDM_TABLE_NAME))
  if (nrow(emptyTables) > 0) {
    emptyTables$TABLE_IS_EMPTY <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, emptyTables, by = c("CDM_TABLE_NAME")),
      TABLE_IS_EMPTY = ifelse(CHECK_NAME != "cdmField" & CHECK_NAME != "cdmTable" & IS_ERROR == 0, TABLE_IS_EMPTY, NA))
  } else {
    checkResults$TABLE_IS_EMPTY <- NA

  }

  emptyFields <-
    dplyr::select(
      dplyr::filter(checkResults, CHECK_NAME == "measureValueCompleteness" &
                      NUM_DENOMINATOR_ROWS == NUM_VIOLATED_ROWS &
                      is.na(TABLE_IS_MISSING) & is.na(FIELD_IS_MISSING) & is.na(TABLE_IS_EMPTY)),
      CDM_TABLE_NAME, CDM_FIELD_NAME)
  if (nrow(emptyFields) > 0) {
    emptyFields$FIELD_IS_EMPTY <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, emptyFields, by = c("CDM_TABLE_NAME", "CDM_FIELD_NAME")),
      FIELD_IS_EMPTY = ifelse(CHECK_NAME != "measureValueCompleteness" & CHECK_NAME != "cdmField" & CHECK_NAME != "isRequired" & IS_ERROR == 0, FIELD_IS_EMPTY, NA))
  } else {
    checkResults$FIELD_IS_EMPTY <- NA
  }

  checkResults <- dplyr::mutate(
    checkResults,
    CONCEPT_IS_MISSING = ifelse(
        IS_ERROR == 0 &
        is.na(TABLE_IS_MISSING) &
        is.na(FIELD_IS_MISSING) &
        is.na(TABLE_IS_EMPTY) &
        is.na(FIELD_IS_EMPTY) &
        CHECK_LEVEL == "CONCEPT" &
        is.na(UNIT_CONCEPT_ID) &
        NUM_DENOMINATOR_ROWS == 0,
      1,
      NA
    )
  )

  checkResults <- dplyr::mutate(
    checkResults,
    CONCEPT_AND_UNIT_ARE_MISSING = ifelse(
        IS_ERROR == 0 &
        is.na(TABLE_IS_MISSING) &
        is.na(FIELD_IS_MISSING) &
        is.na(TABLE_IS_EMPTY) &
        is.na(FIELD_IS_EMPTY) &
        CHECK_LEVEL == "CONCEPT" &
        !is.na(UNIT_CONCEPT_ID) &
        NUM_DENOMINATOR_ROWS == 0,
      1,
      NA
    )
  )

  checkResults <- dplyr::mutate(
    checkResults,
    NOT_APPLICABLE = dplyr::coalesce(TABLE_IS_MISSING, FIELD_IS_MISSING, TABLE_IS_EMPTY, FIELD_IS_EMPTY, CONCEPT_IS_MISSING, CONCEPT_AND_UNIT_ARE_MISSING, 0),
    NOT_APPLICABLE_REASON = dplyr::case_when(
        !is.na(TABLE_IS_MISSING) ~ sprintf("Table %s does not exist.", CDM_TABLE_NAME),
        !is.na(FIELD_IS_MISSING) ~ sprintf("Field %s.%s does not exist.", CDM_TABLE_NAME, CDM_FIELD_NAME),
        !is.na(TABLE_IS_EMPTY) ~ sprintf("Table %s is empty.", CDM_TABLE_NAME),
        !is.na(FIELD_IS_EMPTY) ~ sprintf("Field %s.%s is not populated.", CDM_TABLE_NAME, CDM_FIELD_NAME),
        !is.na(CONCEPT_IS_MISSING) ~ sprintf("%s=%s is missing from the %s table.", CDM_FIELD_NAME, CONCEPT_ID, CDM_TABLE_NAME),
        !is.na(CONCEPT_AND_UNIT_ARE_MISSING) ~ sprintf("Combination of %s=%s, UNIT_CONCEPT_ID=%s and VALUE_AS_NUMBER IS NOT NULL is missing from the %s table.", CDM_FIELD_NAME, CONCEPT_ID, UNIT_CONCEPT_ID, CDM_TABLE_NAME)
      )
  )

  checkResults <- dplyr::select(checkResults, -c(TABLE_IS_MISSING, FIELD_IS_MISSING, TABLE_IS_EMPTY, FIELD_IS_EMPTY, CONCEPT_IS_MISSING, CONCEPT_AND_UNIT_ARE_MISSING))
  checkResults <- dplyr::mutate(checkResults, FAILED = ifelse(NOT_APPLICABLE == 1, 0, FAILED))
  checkResults <- dplyr::mutate(checkResults, PASSED = ifelse(FAILED == 0 & IS_ERROR == 0 & NOT_APPLICABLE == 0, 1, 0))

  checkResults
}

.summarizeResults <- function(connectionDetails,
                              cdmDatabaseSchema,
                              checkResults,
                              cdmSourceName,
                              outputFolder,
                              outputFile,
                              startTime,
                              tableChecks,
                              fieldChecks,
                              conceptChecks,
                              metadata) {
  
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))
  
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
  
  countPassedPlausibility <- nrow(checkResults[checkResults$CATEGORY=='Plausibility' &
                                                 checkResults$PASSED == 1,])

  countPassedConformance <- nrow(checkResults[checkResults$CATEGORY=='Conformance' &
                                                checkResults$PASSED == 1,])

  countPassedCompleteness <- nrow(checkResults[checkResults$CATEGORY=='Completeness' &
                                                 checkResults$PASSED == 1,])
  
  overview <- list(
    countTotal = countTotal, 
    countPassed = countPassed, 
    countErrorFailed = countErrorFailed,
    countThresholdFailed = countThresholdFailed,
    countOverallFailed = countOverallFailed,
    percentPassed = round(countPassed / (countPassed + countOverallFailed) * 100, 2),
    percentFailed = round(countOverallFailed / (countPassed + countOverallFailed) * 100, 2),
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
  
  return(result)
}

resultToJson <- function(result) {
  return(jsonlite::toJSON(result))
}

writeJsonResultToFile <- function(resultJson, outputFolder, outputFile) {
  if (nchar(outputFile)==0)  {
    endTimestamp <- format(endTime, "%Y%m%d%H%M%S")
    outputFile <- sprintf("%s-%s.json", tolower(metadata$CDM_SOURCE_ABBREVIATION),endTimestamp)
  }

  resultFilename <- file.path(outputFolder,outputFile)
  result$outputFile <- outputFile

  ParallelLogger::logInfo(sprintf("Writing results to file: %s", resultFilename))
  write(resultJson, resultFilename)

  result
}

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
  
  df <- dplyr::bind_rows(checkResults)
  
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))
  
  if (length(cohortDefinitionId > 0)){
    tableName <- sprintf("%s.%s_%s", resultsDatabaseSchema,writeTableName, cohortDefinitionId)
  } else {tableName <- sprintf("%s.%s", resultsDatabaseSchema, writeTableName)}
  
  ParallelLogger::logInfo(sprintf("#DQD Writing results to table %s", tableName))
  
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
      ParallelLogger::logInfo("#DQD Finished writing table")
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("#DQD Writing table failed: %s", e$message))
    }
  )
  
  # .writeResultsToTable(connectionDetails = connectionDetails,
  #                      resultsDatabaseSchema = resultsDatabaseSchema,
  #                      checkResults = df)
}

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
  
  ParallelLogger::logInfo(sprintf("#DQD Writing results to table %s", tableName))
  
  ddl <- SqlRender::loadRenderTranslateSql(sqlFilename = "result_dataframe_ddl.sql", packageName = "DataQualityDashboard", tableName = tableName, dbms = connectionDetails$dbms)

  DatabaseConnector::executeSql(connection = connection, sql = ddl, progressBar = TRUE)
  
  tryCatch(
    expr = {
      DatabaseConnector::insertTable(connection = connection, tableName = tableName, data = checkResults, 
                                     dropTableIfExists = FALSE, createTable = FALSE, tempTable = FALSE)
      ParallelLogger::logInfo("#DQD Finished writing table")
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("#DQD Writing table failed: %s", e$message))
    }
  )
}

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
