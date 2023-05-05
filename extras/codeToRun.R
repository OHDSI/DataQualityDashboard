# Copyright 2023 Observational Health Data Sciences and Informatics
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

library(DataQualityDashboard)
library(DatabaseConnector)

# fill out the connection details -----------------------------------------------------------------------
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "",
  user = "",
  password = "",
  server = "",
  port = "",
  extraSettings = "",
  pathToDriver = ""
)

cdmDatabaseSchema <- "yourCdmSchema" # the fully qualified database schema name of the CDM
resultsDatabaseSchema <- "yourResultsSchema" # the fully qualified database schema name of the results schema (that you can write to)
cdmSourceName <- "Your CDM Source" # a human readable name for your CDM source
cdmVersion <- "5.4" # the CDM version you are targetting. Currently supporst 5.2.2, 5.3.1, and 5.4

# determine how many threads (concurrent SQL sessions) to use ----------------------------------------
numThreads <- 1 # on Redshift, 3 seems to work well

# specify if you want to execute the queries or inspect them ------------------------------------------
sqlOnly <- FALSE # set to TRUE if you just want to get the SQL scripts and not actually run the queries

# where should the results and logs go? ----------------------------------------------------------------
outputFolder <- "output"
outputFile <- "results.json"

# logging type -------------------------------------------------------------------------------------
verboseMode <- TRUE # set to FALSE if you don't want the logs to be printed to the console

# write results to table? -----------------------------------------------------------------------
writeToTable <- FALSE # set to TRUE if you want to write to a SQL table in the results schema

# write results to a csv file? -----------------------------------------------------------------------
writeToCsv <- FALSE # set to FALSE if you want to skip writing to csv file
csvFile <- "" # only needed if writeToCsv is set to TRUE

# if writing to table and using Redshift, bulk loading can be initialized -------------------------------
# Sys.setenv("AWS_ACCESS_KEY_ID" = "",
#            "AWS_SECRET_ACCESS_KEY" = "",
#            "AWS_DEFAULT_REGION" = "",
#            "AWS_BUCKET_NAME" = "",
#            "AWS_OBJECT_KEY" = "",
#            "AWS_SSE_TYPE" = "AES256",
#            "USE_MPP_BULK_LOAD" = TRUE)

# which DQ check levels to run -------------------------------------------------------------------
checkLevels <- c("TABLE", "FIELD", "CONCEPT")

# which DQ checks to run? ------------------------------------
checkNames <- c() # Names can be found in inst/csv/OMOP_CDM_v5.3.1_Check_Desciptions.csv

# which CDM tables to exclude? ------------------------------------
tablesToExclude <- c()

# run the job --------------------------------------------------------------------------------------
DataQualityDashboard::executeDqChecks(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  resultsDatabaseSchema = resultsDatabaseSchema,
  cdmSourceName = cdmSourceName,
  cdmVersion = cdmVersion
  numThreads = numThreads,
  sqlOnly = sqlOnly, 
  outputFolder = outputFolder,
  outputFile = outputFile,
  verboseMode = verboseMode,
  writeToTable = writeToTable,
  writeToCsv = writeToCsv,
  csvFile = csvFile,
  checkLevels = checkLevels,
  tablesToExclude = tablesToExclude,
  checkNames = checkNames
)

# inspect logs ----------------------------------------------------------------------------
ParallelLogger::launchLogViewer(
  logFileName = file.path(outputFolder,
  sprintf("log_DqDashboard_%s.txt", cdmSourceName))
)

# View the Data Quality Dashboard using the integrated shiny application ------------------------------------
DataQualityDashboard::viewDqDashboard(
  jsonPath = file.path(getwd(), outputFolder, outputFile)
)

# (OPTIONAL) if you want to write the JSON file to the results table separately -----------------------------
jsonFilePath <- "" # put the path to the outputted JSON file
DataQualityDashboard::writeJsonResultsToTable(
  connectionDetails = connectionDetails,
  resultsDatabaseSchema = resultsDatabaseSchema,
  jsonFilePath = jsonFilePath
)
