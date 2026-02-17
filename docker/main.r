install.packages(".", repos = NULL, type = "source")

# fill out the connection details -----------------------------------------------------------------------

Sys.setenv("DATABASECONNECTOR_JAR_FOLDER" = "/tmp/jars")

# Required for Snowflake JDBC driver with Java 17+ (Apache Arrow memory access)
Sys.setenv("JAVA_TOOL_OPTIONS" = paste(
  "--add-opens=java.base/java.nio=ALL-UNNAMED",
  "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED"
))

if (!dir.exists("/tmp/jars")) {
  DatabaseConnector::downloadJdbcDrivers("snowflake")
}

# Load required libraries (needed when sourcing R files directly instead of loading as a package)
library(magrittr)
library(stringr)
library(rlang)
library(tidyselect)
library(readr)
library(dplyr)
library(jsonlite)
library(SqlRender)
library(ParallelLogger)
library(plyr, warn.conflicts = FALSE)

# Load DataQualityDashboard package (installed from local source)
library(DataQualityDashboard)

# Load environment variables from .env file
if (file.exists(".env")) {
  readRenviron(".env")
}

# Create connection details from environment variables
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "snowflake",
  connectionString = Sys.getenv("SNOWFLAKE_CONNECTION_STRING"),
  user = Sys.getenv("SNOWFLAKE_USER"),
  password = Sys.getenv("SNOWFLAKE_PASSWORD"),
  pathToDriver = "/tmp/jars"
)

# Schema and database details from environment variables
cdmDatabaseSchema <- Sys.getenv("CDM_DATABASE_SCHEMA")
resultsDatabaseSchema <- Sys.getenv("RESULTS_DATABASE_SCHEMA")
cdmSourceName <- Sys.getenv("CDM_SOURCE_NAME")
cdmVersion <- Sys.getenv("CDM_VERSION", unset = "5.4")

# Set the number of threads for parallel processing
numThreads <- 1

# Specify whether to execute queries or just generate SQL scripts
sqlOnly <- FALSE
sqlOnlyIncrementalInsert <- FALSE
sqlOnlyUnionCount <- 1  # Adjust for performance as needed

# Results output configuration
outputFolder <- "output"
outputFile <- "results.json"

# Logging configuration
verboseMode <- TRUE

# Write results to SQL table and/or CSV file
writeToTable <- FALSE
writeToCsv <- FALSE
csvFile <- ""

# List of DQ check levels and checks to run
checkLevels <- c("TABLE", "FIELD", "CONCEPT")
checkNames <- c()

# Tables to exclude from checks
tablesToExclude <- c(
  "COHORT",
  "COHORT_DEFINITION",
  "CONDITION_ERA",
  "COST",
  "DOSE_ERA",
  "DRUG_ERA",
  "EPISODE",
  "EPISODE_EVENT",
  "FACT_RELATIONSHIP",
  "NOTE",
  "NOTE_NLP",
  "OBSERVATION_PERIOD",
  "PAYER_PLAN_PERIOD",
  "SOURCE_TO_CONCEPT_MAP",
  "SPECIMEN",
  "VISIT_DETAIL"
)

checksToExclude <- c(
  "FIELD_isForeignKey_CONDITION_OCCURRENCE_VISIT_DETAIL_ID",
  "FIELD_isForeignKey_DEVICE_EXPOSURE_VISIT_DETAIL_ID",
  "FIELD_isForeignKey_DRUG_EXPOSURE_VISIT_DETAIL_ID",
  "FIELD_isForeignKey_MEASUREMENT_VISIT_DETAIL_ID",
  "FIELD_isForeignKey_OBSERVATION_VISIT_DETAIL_ID",
  "FIELD_isForeignKey_PROCEDURE_OCCURRENCE_VISIT_DETAIL_ID"
)

# Execute the data quality checks
results <- executeDqChecks(
  connectionDetails = connectionDetails, 
  cdmDatabaseSchema = cdmDatabaseSchema, 
  resultsDatabaseSchema = resultsDatabaseSchema,
  cohortDatabaseSchema = Sys.getenv("COHORT_DATABASE_SCHEMA"),
  cdmSourceName = cdmSourceName, 
  cdmVersion = cdmVersion,
  numThreads = numThreads,
  sqlOnly = sqlOnly, 
  sqlOnlyUnionCount = sqlOnlyUnionCount,
  sqlOnlyIncrementalInsert = sqlOnlyIncrementalInsert,
  outputFolder = outputFolder,
  outputFile = outputFile,
  verboseMode = verboseMode,
  writeToTable = writeToTable,
  writeToCsv = writeToCsv,
  csvFile = csvFile,
  checkLevels = checkLevels,
  tablesToExclude = tablesToExclude,
  checkNames = checkNames,
  checksToExclude = checksToExclude
)

# Check for test failures and exit with error code if failures detected
if (!is.null(results) && !is.null(results$CheckResults)) {
  checkResults <- results$CheckResults
  
  # Count execution errors (SQL errors during check execution)
  executionErrors <- sum(!is.na(checkResults$error), na.rm = TRUE)
  
  # Count failed tests (checks that didn't meet threshold requirements)
  failedTests <- sum(checkResults$error == "FAILED", na.rm = TRUE)
  
  # Also check if there are any NA errors that indicate failures (in case error column contains failure status)
  if ("status" %in% names(checkResults)) {
    failedTests <- failedTests + sum(checkResults$status == "FAILED", na.rm = TRUE)
  }
  
  totalFailures <- executionErrors + failedTests
  
  if (totalFailures > 0) {
    cat("\n========================================\n")
    cat("DQD completed with failures:\n")
    cat("  - Execution errors: ", executionErrors, "\n")
    cat("  - Failed tests: ", failedTests, "\n")
    cat("========================================\n")
    quit(status = 1)
  }
}
