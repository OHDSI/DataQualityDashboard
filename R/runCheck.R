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
#' @param outputFile                (OPTIONAL) File to re-use results of previous execution if resume is set
#' @param sqlOnly                   Should the SQLs be executed (FALSE) or just returned (TRUE)?
#' @param resume                    Boolean to indicate if processing will be resumed
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
                      outputFile = "",
                      sqlOnly,
                      resume) {
  ParallelLogger::logInfo(sprintf("Processing check description: %s", checkDescription$checkName))

  filterExpression <- sprintf(
    "%sChecks %%>%% dplyr::filter(%s)",
    tolower(checkDescription$checkLevel),
    checkDescription$evaluationFilter
  )
  checks <- eval(parse(text = filterExpression))

  if (length(cohortDefinitionId > 0)) {
    cohort <- TRUE
  } else {
    cohort <- FALSE
  }

  if (sqlOnly) {
    unlink(file.path(outputFolder, sprintf("%s.sql", checkDescription$checkName)))
  }

  if (nrow(checks) > 0) {
    recoveredNumber <- 0
    checkResultsSaved <- NULL
    if (resume && nchar(outputFile) > 0 && file.exists(file.path(outputFolder, outputFile))) {
      dqdResults <- jsonlite::read_json(
        path = file.path(outputFolder, outputFile)
      )
      checkResultsSaved <- lapply(
        dqdResults$CheckResults,
        function(cr) {
          cr[sapply(cr, is.null)] <- NA
          as.data.frame(cr)
        }
      )
      checkResultsSaved <- do.call(plyr::rbind.fill, checkResultsSaved)
    }
    dfs <- apply(X = checks, MARGIN = 1, function(check) {
      columns <- lapply(names(check), function(c) {
        setNames(check[c], c)
      })

      params <- c(
        list(dbms = connectionDetails$dbms),
        list(sqlFilename = checkDescription$sqlFile),
        list(packageName = "DataQualityDashboard"),
        list(warnOnMissingParameters = FALSE),
        list(cdmDatabaseSchema = cdmDatabaseSchema),
        list(cohortDatabaseSchema = cohortDatabaseSchema),
        list(cohortDefinitionId = cohortDefinitionId),
        list(vocabDatabaseSchema = vocabDatabaseSchema),
        list(cohort = cohort),
        unlist(columns, recursive = FALSE)
      )

      sql <- do.call(SqlRender::loadRenderTranslateSql, params)

      if (sqlOnly) {
        write(x = sql, file = file.path(
          outputFolder,
          sprintf("%s.sql", checkDescription$checkName)
        ), append = TRUE)
        data.frame()
      } else {
        checkResult <- NULL
        if (!is.null(checkResultsSaved)) {
          currentCheckId <- .getCheckId(
            checkLevel = checkDescription$checkLevel,
            checkName = checkDescription$checkName,
            cdmTableName = check["cdmTableName"],
            cdmFieldName = check["cdmFieldName"],
            conceptId = check["conceptId"],
            unitConceptId = check["unitConceptId"]
          )
          checkResultCandidates <- checkResultsSaved %>% dplyr::filter(checkId == currentCheckId & is.na(ERROR))
          if (1 == nrow(checkResultCandidates)) {
              savedResult <- checkResultCandidates[1, ]
              warning <- if (is.null(savedResult$WARNING)) { NA } else { savedResult$WARNING }
              checkResult <- .recordResult(
                result = savedResult,
                check = check,
                checkDescription = checkDescription,
                sql = sql,
                executionTime = savedResult$EXECUTION_TIME,
                warning = warning,
                error = NA
              )
              recoveredNumber <<- recoveredNumber + 1
          }
        }

        if (is.null(checkResult)) {
          checkResult <- .processCheck(
            connection = connection,
            connectionDetails = connectionDetails,
            check = check,
            checkDescription = checkDescription,
            sql = sql,
            outputFolder = outputFolder
          )
        }

        checkResult
      }
    })

    if (recoveredNumber > 0) {
      ParallelLogger::logInfo(sprintf("Recovered %s of %s results from %s", recoveredNumber, nrow(checks), outputFile))
    }

    do.call(rbind, dfs)
  } else {
    ParallelLogger::logWarn(paste0("Warning: Evaluation resulted in no checks: ", filterExpression))
    data.frame()
  }
}
