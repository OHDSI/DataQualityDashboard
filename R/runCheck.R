# Copyright 2025 Observational Health Data Sciences and Informatics
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
#' @param tableChecks               A dataframe containing the table checks
#' @param fieldChecks               A dataframe containing the field checks
#' @param conceptChecks             A dataframe containing the concept checks
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database
#' @param connection                A connection for connecting to the CDM database using the DatabaseConnector::connect(connectionDetails) function.
#' @param cdmDatabaseSchema         The fully qualified database name of the CDM schema
#' @param vocabDatabaseSchema       The fully qualified database name of the vocabulary schema (default is to set it as the cdmDatabaseSchema)
#' @param resultsDatabaseSchema     The fully qualified database name of the results schema
#' @param writeTableName            The table tor write DQD results to. Used when sqlOnly or writeToTable is True.
#' @param cohortDatabaseSchema      The schema where the cohort table is located.
#' @param cohortTableName           The name of the cohort table.
#' @param cohortDefinitionId        The cohort definition id for the cohort you wish to run the DQD on. The package assumes a standard OHDSI cohort table called 'Cohort'
#' @param outputFolder              The folder to output logs and SQL files to
#' @param sqlOnlyUnionCount         (OPTIONAL) How many SQL commands to union before inserting them into output table (speeds processing when queries done in parallel). Default is 1.
#' @param sqlOnlyIncrementalInsert  (OPTIONAL) Boolean to determine whether insert check results and associated metadata into output table.  Default is FALSE (for backwards compatability to <= v2.2.0)
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
                      resultsDatabaseSchema,
                      writeTableName,
                      cohortDatabaseSchema,
                      cohortTableName,
                      cohortDefinitionId,
                      outputFolder,
                      sqlOnlyUnionCount,
                      sqlOnlyIncrementalInsert,
                      sqlOnly) {
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

  if (nrow(checks) > 0) {
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
        list(cohortTableName = cohortTableName),
        list(cohortDefinitionId = cohortDefinitionId),
        list(vocabDatabaseSchema = vocabDatabaseSchema),
        list(cohort = cohort),
        unlist(columns, recursive = FALSE)
      )

      sql <- do.call(SqlRender::loadRenderTranslateSql, params)

      if (sqlOnly && sqlOnlyIncrementalInsert) {
        checkQuery <- .createSqlOnlyQueries(
          params,
          check,
          tableChecks,
          fieldChecks,
          conceptChecks,
          sql,
          connectionDetails,
          checkDescription
        )
        data.frame(query = checkQuery)
      } else if (sqlOnly) {
        write(x = sql, file = file.path(
          outputFolder,
          sprintf("%s.sql", checkDescription$checkName)
        ), append = TRUE)
        data.frame()
      } else {
        .processCheck(
          connection = connection,
          connectionDetails = connectionDetails,
          check = check,
          checkDescription = checkDescription,
          sql = sql,
          outputFolder = outputFolder
        )
      }
    })

    dfs <- do.call(rbind, dfs)

    if (sqlOnly && sqlOnlyIncrementalInsert) {
      sqlToUnion <- dfs$query
      if (length(sqlToUnion) > 0) {
        .writeSqlOnlyQueries(sqlToUnion, sqlOnlyUnionCount, resultsDatabaseSchema, writeTableName, connectionDetails$dbms, outputFolder, checkDescription)
      }
    } else {
      dfs
    }
  } else {
    ParallelLogger::logWarn(paste0("Warning: Evaluation resulted in no checks: ", filterExpression))
    data.frame()
  }
}
