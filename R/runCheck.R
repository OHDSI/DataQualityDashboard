# @file runCheck.R
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


#' SUPPORT FUNCTION 
#' referenced in execution.R
#' 
#' This function will run each check detailed in each of the csv files against the CDM instance specified 
#' 
#' @param checkDescription The description of each check type as detailed in checkDescriptions.csv
#' @param tableChecks The name of the R object containing the table checks
#' @param fieldChecks The name of the R object containing the field checks
#' @param conceptChecks The name of the R object containing the concept checks
#' @param connectionDetails A connectionDetails object for connecting to the CDM database
#' @param connection The connection object created using the connectionDetails object
#' @param cdmDatabaseSchema The CDM schema where the data quality checks should be run
#' @param outputFolder The place where the results should be written
#' @param sqlOnly A boolean object indicating whether the checks should be executed or if only the sql should be written
#' 

.runCheck <- function(checkDescription, 
                      tableChecks,
                      fieldChecks,
                      conceptChecks,
                      connectionDetails,
                      connection,
                      cdmDatabaseSchema, 
                      cohort,
                      cohortDatabaseSchema,
                      cohortDefinitionId,
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
                  list(cohort = cohort),
                  list(cohortDatabaseSchema = cohortDatabaseSchema),
                  list(cohortDefinitionId = cohortDefinitionId),
                  unlist(columns, recursive = FALSE))
# add cohort inclusion flags here      
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
