# Copyright 2022 Observational Health Data Sciences and Informatics
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

#' @title Execute DQ checks
#'
#' @description This function will connect to the database, generate the sql scripts, and run the data quality checks against the database.
#'
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param cdmDatabaseSchema         The fully qualified database name of the CDM schema
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param vocabDatabaseSchema       The fully qualified database name of the vocabulary schema (default is to set it as the cdmDatabaseSchema)
#' @param numThreads                The number of concurrent threads to use to execute the queries
#' @param cdmSourceName             The name of the CDM data source
#' @param sqlOnly                   Should the SQLs be executed (FALSE) or just returned (TRUE)?
#' @param outputFolder              The folder to output logs, SQL files, and JSON results file to
#' @param outputFile                (OPTIONAL) File to write results JSON object
#' @param verboseMode               Boolean to determine if the console will show all execution steps. Default = FALSE
#' @param writeToTable              Boolean to indicate if the check results will be written to the dqdashboard_results table
#' @param writeTableName            The name of the results table. Defaults to `dqdashboard_results`.
#' @param writeToCsv                Boolean to indicate if the check results will be written to a csv file
#' @param csvFile                   (OPTIONAL) CSV file to write results
#'                                  in the resultsDatabaseSchema. Default is TRUE.
#' @param checkLevels               Choose which DQ check levels to execute. Default is all 3 (TABLE, FIELD, CONCEPT)
#' @param checkNames                (OPTIONAL) Choose which check names to execute. Names can be found in inst/csv/OMOP_CDM_v[cdmVersion]_Check_Descriptions.csv. Note that "cdmTable", "cdmField" and "measureValueCompleteness" are always executed.
#' @param cohortDefinitionId        The cohort definition id for the cohort you wish to run the DQD on. The package assumes a standard OHDSI cohort table called 'Cohort'
#'                                  with the fields cohort_definition_id and subject_id.
#' @param cohortDatabaseSchema      The schema where the cohort table is located.
#' @param tablesToExclude           (OPTIONAL) Choose which CDM tables to exclude from the execution.
#' @param cdmVersion                The CDM version to target for the data source. Options are "5.2", "5.3", or "5.4". By default, "5.3" is used.
#' @param tableCheckThresholdLoc    The location of the threshold file for evaluating the table checks. If not specified the default thresholds will be applied.
#' @param fieldCheckThresholdLoc    The location of the threshold file for evaluating the field checks. If not specified the default thresholds will be applied.
#' @param conceptCheckThresholdLoc  The location of the threshold file for evaluating the concept checks. If not specified the default thresholds will be applied.
#'
#' @return If sqlOnly = FALSE, a list object of results
#'
#' @importFrom magrittr %>%
#' @import DatabaseConnector
#' @importFrom stringr str_detect regex
#' @importFrom utils packageVersion read.csv
#'
#' @export
#'
executeDqChecks <- function(connectionDetails,
                            cdmDatabaseSchema,
                            resultsDatabaseSchema,
                            vocabDatabaseSchema = cdmDatabaseSchema,
                            cdmSourceName,
                            numThreads = 1,
                            sqlOnly = FALSE,
                            outputFolder,
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
                            cdmVersion = "5.3",
                            tableCheckThresholdLoc = "default",
                            fieldCheckThresholdLoc = "default",
                            conceptCheckThresholdLoc = "default") {
  # Check input -------------------------------------------------------------------------------------------------------------------
  if (!any(class(connectionDetails) %in% c("connectionDetails", "ConnectionDetails"))) {
    stop("connectionDetails must be an object of class 'connectionDetails' or 'ConnectionDetails'.")
  }

  if (!str_detect(cdmVersion, regex(ACCEPTED_CDM_REGEX))) {
    stop("cdmVersion must contain a version of the form '5.X' where X is an integer between 2 and 4 inclusive.")
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
  if (!length(checkNames) == 0) {
    naCheckNames <- c("cdmTable", "cdmField", "measureValueCompleteness")
    missingNAChecks <- !(naCheckNames %in% checkNames)
    if (any(missingNAChecks)) {
      missingNACheckNames <- paste(naCheckNames[missingNAChecks], collapse = ", ")
      warning(sprintf("Missing check names to calculate the 'Not Applicable' status: %s", missingNACheckNames))
    }
  }

  # capture metadata -----------------------------------------------------------------------
  if (!sqlOnly) {
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    sql <- SqlRender::render(
      sql = "select * from @cdmDatabaseSchema.cdm_source;",
      cdmDatabaseSchema = cdmDatabaseSchema
    )
    sql <- SqlRender::translate(sql = sql, targetDialect = connectionDetails$dbms)
    metadata <- DatabaseConnector::querySql(connection = connection, sql = sql)
    if (nrow(metadata) < 1) {
      stop("Please populate the cdm_source table before executing data quality checks.")
    }
    metadata$DQD_VERSION <- as.character(packageVersion("DataQualityDashboard"))
    DatabaseConnector::disconnect(connection)
  } else {
    metadata <- NA
  }

  # Setup output folder ------------------------------------------------------------------------------------------------------------
  if (!dir.exists(outputFolder)) {
    dir.create(path = outputFolder, recursive = TRUE)
  }

  if (dir.exists(file.path(outputFolder, "errors"))) {
    unlink(file.path(outputFolder, "errors"), recursive = TRUE)
  }

  dir.create(file.path(outputFolder, "errors"), recursive = TRUE)

  # Log execution -----------------------------------------------------------------------------------------------------------------
  logFileName <- sprintf("log_DqDashboard_%s.txt", cdmSourceName)
  unlink(file.path(outputFolder, logFileName))

  if (verboseMode) {
    appenders <- list(
      ParallelLogger::createConsoleAppender(layout = ParallelLogger::layoutTimestamp),
      ParallelLogger::createFileAppender(
        layout = ParallelLogger::layoutParallel,
        fileName = file.path(outputFolder, logFileName)
      )
    )
  } else {
    appenders <- list(ParallelLogger::createFileAppender(
      layout = ParallelLogger::layoutParallel,
      fileName = file.path(outputFolder, logFileName)
    ))
  }


  logger <- ParallelLogger::createLogger(
    name = "DqDashboard",
    threshold = "INFO",
    appenders = appenders
  )
  ParallelLogger::registerLogger(logger = logger)
  on.exit(ParallelLogger::unregisterLogger("DqDashboard", silent = TRUE))

  # load Threshold CSVs ----------------------------------------------------------------------------------------

  startTime <- Sys.time()

  checkDescriptionsDf <- read.csv(
    file = system.file(
      "csv",
      sprintf("OMOP_CDMv%s_Check_Descriptions.csv", cdmVersion),
      package = "DataQualityDashboard"
    ),
    stringsAsFactors = FALSE
  )

  tableChecks <- .readThresholdFile(
    checkThresholdLoc = tableCheckThresholdLoc,
    defaultLoc = sprintf("OMOP_CDMv%s_Table_Level.csv", cdmVersion)
  )

  fieldChecks <- .readThresholdFile(
    checkThresholdLoc = fieldCheckThresholdLoc,
    defaultLoc = sprintf("OMOP_CDMv%s_Field_Level.csv", cdmVersion)
  )

  conceptChecks <- .readThresholdFile(
    checkThresholdLoc = conceptCheckThresholdLoc,
    defaultLoc = sprintf("OMOP_CDMv%s_Concept_Level.csv", cdmVersion)
  )

  # ensure we use only checks that are intended to be run -----------------------------------------

  if (length(tablesToExclude) > 0) {
    tablesToExclude <- toupper(tablesToExclude)
    ParallelLogger::logInfo(sprintf("CDM Tables skipped: %s", paste(tablesToExclude, collapse = ", ")))
    tableChecks <- tableChecks[!tableChecks$cdmTableName %in% tablesToExclude, ]
    fieldChecks <- fieldChecks[!fieldChecks$cdmTableName %in% tablesToExclude, ]
    conceptChecks <- conceptChecks[!conceptChecks$cdmTableName %in% tablesToExclude, ]
  }

  ## remove offset from being checked
  fieldChecks <- subset(fieldChecks, cdmFieldName != "offset")

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
    checkDescriptionsDf <- checkDescriptionsDf[checkDescriptionsDf$checkName %in% checkNames, ]
  }

  if (nrow(checkDescriptionsDf) == 0) {
    stop("No checks are available based on excluded tables. Please review tablesToExclude.")
  }

  checkDescriptions <- split(checkDescriptionsDf, seq_len(nrow(checkDescriptionsDf)))

  connection <- NULL
  if (numThreads == 1 && !sqlOnly) {
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  }

  fieldChecks$cdmFieldName <- toupper(fieldChecks$cdmFieldName)
  conceptChecks$cdmFieldName <- toupper(conceptChecks$cdmFieldName)

  cluster <- ParallelLogger::makeCluster(numberOfThreads = numThreads, singleThreadToMain = TRUE)
  resultsList <- ParallelLogger::clusterApply(
    cluster = cluster, x = checkDescriptions,
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
    progressBar = TRUE
  )
  ParallelLogger::stopCluster(cluster = cluster)

  if (numThreads == 1 && !sqlOnly) {
    DatabaseConnector::disconnect(connection = connection)
  }

  allResults <- NULL
  if (!sqlOnly) {
    checkResults <- do.call(rbind, resultsList)

    # evaluate thresholds-------------------------------------------------------------------
    checkResults <- .evaluateThresholds(
      checkResults = checkResults,
      tableChecks = tableChecks,
      fieldChecks = fieldChecks,
      conceptChecks = conceptChecks
    )

    # create overview
    overview <- .summarizeResults(checkResults = checkResults)

    endTime <- Sys.time()
    delta <- endTime - startTime

    # Create result
    allResults <- list(
      startTimestamp = startTime,
      endTimestamp = endTime,
      executionTime = sprintf("%.0f %s", delta, attr(delta, "units")),
      CheckResults = checkResults,
      Metadata = metadata,
      Overview = overview
    )

    # Write result
    if (nchar(outputFile) == 0) {
      endTimestamp <- format(endTime, "%Y%m%d%H%M%S")
      outputFile <- sprintf("%s-%s.json", tolower(metadata$CDM_SOURCE_ABBREVIATION), endTimestamp)
    }

    .writeResultsToJson(allResults, outputFolder, outputFile)

    ParallelLogger::logInfo("Execution Complete")
  }


  # write to table ----------------------------------------------------------------------

  if (!sqlOnly && writeToTable) {
    .writeResultsToTable(
      connectionDetails = connectionDetails,
      resultsDatabaseSchema = resultsDatabaseSchema,
      checkResults = allResults$CheckResults,
      writeTableName = writeTableName,
      cohortDefinitionId = cohortDefinitionId
    )
  }

  # write to CSV ----------------------------------------------------------------------

  if (!sqlOnly && writeToCsv) {
    if (nchar(csvFile) == 0) {
      csvFile <- sprintf("%s.csv", sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(allResults$outputFile)))
    }
    .writeResultsToCsv(
      checkResults = allResults$CheckResults,
      csvPath = file.path(outputFolder, csvFile)
    )
  }

  if (sqlOnly) {
    invisible(allResults)
  } else {
    return(allResults)
  }
}

.needsAutoCommit <- function(connectionDetails, connection) {
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
