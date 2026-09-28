# Copyright 2026 Observational Health Data Sciences and Informatics
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
#' @param futureDate                Reference "future" date ('YYYY-MM-DD') for plausibleValueHigh checks. NULL keeps the legacy GETDATE() behavior (sqlOnly mode) or marks the checks not-applicable when cdm_source.source_release_date is missing.
#'
#' @return A dataframe containing the check results or SQL queries (NULL if sqlOnlyIncrementalInsert is TRUE)
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
                      sqlOnly,
                      futureDate) {
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

      # Resolve the @futureDate placeholder in the plausibleValueHigh threshold (#277).
      # futureDate is a 'YYYY-MM-DD' string; NULL in sqlOnly mode (legacy
      # GETDATE() behavior) or when cdm_source.source_release_date is missing.
      # In the latter case the check cannot be evaluated honestly, so it is
      # skipped and marked not-applicable instead of executed.
      needsFutureDate <- "plausibleValueHigh" %in% names(params) &&
        !is.na(params$plausibleValueHigh) &&
        grepl("@futureDate", params$plausibleValueHigh, fixed = TRUE)

      if (needsFutureDate && !sqlOnly && is.null(futureDate)) {
        return(.recordFutureDateSkipped(
          check = check,
          checkDescription = checkDescription
        ))
      }

      if (needsFutureDate) {
        params$plausibleValueHigh <- .resolveFutureDatePlaceholder(params$plausibleValueHigh, futureDate)
      }

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
        return(NULL)
      }
    } else {
      return(dfs)
    }
  } else {
    ParallelLogger::logWarn(paste0("Warning: Evaluation resulted in no checks: ", filterExpression))
    return(data.frame())
  }
}

#' Resolve the @futureDate placeholder in a check threshold value.
#'
#' Replaces the `@futureDate` placeholder used in plausibleValueHigh control-file
#' thresholds with a deterministic date literal. See issue #277: thresholds that
#' reference GETDATE() make repeated runs over the same data return different
#' results depending on the run date.
#'
#' @param thresholdValue  The threshold expression from the control file, e.g. "DATEADD(dd,1,@futureDate)"
#' @param futureDate      A 'YYYY-MM-DD' date string, or NULL to keep the legacy GETDATE() behavior
#'
#' @return The threshold expression with the placeholder resolved
#'
#' @keywords internal
.resolveFutureDatePlaceholder <- function(thresholdValue, futureDate) {
  futureDateSql <- if (is.null(futureDate)) {
    "CAST(GETDATE() AS DATE)"
  } else {
    sprintf("'%s'", futureDate)
  }
  gsub("@futureDate", futureDateSql, thresholdValue, fixed = TRUE)
}

#' Record a future-date check that was not executed (#277).
#'
#' Used when cdm_source.source_release_date is missing: without a release date
#' there is no honest definition of "future", so the check SQL is never
#' executed. The result row is flagged via `futureDateSkipped` and
#' .calculateNotApplicableStatus() marks it not-applicable.
#'
#' @param check             The data quality check
#' @param checkDescription  The description of the data quality check
#'
#' @return A single-row dataframe with the check marked as skipped
#'
#' @keywords internal
.recordFutureDateSkipped <- function(check, checkDescription) {
  ParallelLogger::logInfo(sprintf(
    "Skipping check %s on %s.%s: cdm_source.source_release_date is missing, no reference future date available (#277).",
    checkDescription$checkName, check["cdmTableName"], check["cdmFieldName"]
  ))
  result <- .recordResult(
    check = check,
    checkDescription = checkDescription,
    sql = NA,
    warning = paste0(
      "Check not executed: cdm_source.source_release_date is missing, ",
      "so no reference future date is available. Supply futureDate explicitly to run this check."
    )
  )
  result$futureDateSkipped <- TRUE
  result
}

#' Determine the default reference "future" date from the CDM source (#277).
#'
#' Used as the default `futureDate` for plausibleValueHigh checks: the
#' `cdm_source.source_release_date`, so check results are deterministic across
#' runs. Returns NULL when the release date is missing or cannot be determined;
#' callers must then skip the affected checks and mark them not-applicable
#' rather than falling back to the current date (which would reintroduce
#' run-to-run variance, defeating the purpose of #277).
#'
#' @param connection          A live DatabaseConnector connection to the CDM database
#' @param connectionDetails   A connectionDetails object for connecting to the CDM database
#' @param cdmDatabaseSchema   The fully qualified database name of the CDM schema
#'
#' @return A 'YYYY-MM-DD' date string, or NULL when the release date is unavailable
#'
#' @keywords internal
.getSourceReleaseDate <- function(connection, connectionDetails, cdmDatabaseSchema) {
  sql <- SqlRender::render(
    sql = "SELECT MAX(source_release_date) AS release_date FROM @cdmDatabaseSchema.cdm_source;",
    cdmDatabaseSchema = cdmDatabaseSchema
  )
  sql <- SqlRender::translate(sql = sql, targetDialect = connectionDetails$dbms)
  result <- tryCatch(
    DatabaseConnector::querySql(connection = connection, sql = sql),
    error = function(e) {
      warning("Could not query CDM_SOURCE for source_release_date (#277); future-date checks will be skipped. Details: ", e$message)
      NULL
    }
  )
  rawDate <- if (!is.null(result) && nrow(result) > 0) result[[1]][1] else NA
  releaseDate <- tryCatch(
    {
      if (inherits(rawDate, "Date")) {
        rawDate
      } else if (is.numeric(rawDate)) {
        as.Date(rawDate, origin = "1970-01-01")
      } else {
        as.Date(as.character(rawDate))
      }
    },
    error = function(e) as.Date(NA)
  )
  if (is.na(releaseDate)) {
    warning("CDM_SOURCE contains no usable source_release_date; future-date checks will be skipped and marked not-applicable (#277).")
    return(NULL)
  }
  format(releaseDate, "%Y-%m-%d")
}
