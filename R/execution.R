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
#' @param checkNames                (OPTIONAL) Choose which check names to execute. Names can be found in inst/csv/OMOP_CDM_v5.3.1_Check_Desciptions.csv
#' @param tablesToExclude           (OPTIONAL) Choose which CDM tables to exclude from the execution.
#' 
#' @return If sqlOnly = FALSE, a list object of results
#' 
#' @export
executeDqChecks <- function(connectionDetails,
                            cdmDatabaseSchema,
                            resultsDatabaseSchema,
                            cdmSourceName,
                            cohort = FALSE,
                            cohortDefinitionId = c(),
                            cohortDatabaseSchema = "", #TODO add cohortTable
                            numThreads = 1,
                            sqlOnly = FALSE,
                            outputFolder = "output",
                            verboseMode = FALSE,
                            writeToTable = TRUE,
                            checkLevels = c("TABLE", "FIELD", "CONCEPT"),
                            checkNames = c(),
                            tablesToExclude = c()) {
  
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
  
  checkDescriptionsDf <- read.csv(system.file("csv", "OMOP_CDMv5.3.1_Check_Descriptions.csv", 
                                            package = "DataQualityDashboard"), 
                                stringsAsFactors = FALSE)
  tableChecks <- read.csv(system.file("csv", "OMOP_CDMv5.3.1_Table_Level.csv",
                                      package = "DataQualityDashboard"), 
                          stringsAsFactors = FALSE)
  fieldChecks <- read.csv(system.file("csv", "OMOP_CDMv5.3.1_Field_Level.csv",
                                      package = "DataQualityDashboard"), 
                          stringsAsFactors = FALSE)
  conceptChecks <- read.csv(system.file("csv", "OMOP_CDMv5.3.1_Concept_Level.csv",
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
                                              cohort,
                                              cohortDatabaseSchema,
                                              cohortDefinitionId,
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
