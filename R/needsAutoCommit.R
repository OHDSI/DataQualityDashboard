# @file needsAutoCommit.R
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
#' Creates an object called 'autocommit' that can either be TRUE or FALSE
#' based on the dbms in order to determine if statements should be automatically 
#' committed once submitted. For PostgreSQL and Redshift this will be set to 
#' TRUE, otherwise it will be set to FALSE.
#' 
#' @param connection  Connection object created using the DatabaseConnector package and connectionDetails object
#' 

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