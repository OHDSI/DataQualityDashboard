#' This is an example of how to run DQD in sqlOnlyIncrementalInsert mode
#' There are two main advantages of running DQD in  sqlOnlyIncrementalInsert mode:
#' - Create queries locally, before sending to server. This allows for inspection of code before execution.
#' - Faster. With sqlOnlyUnionCount > 1 multiple checks can be executed in parallel in one query.

library(DataQualityDashboard)

# ConnectionDetails object needed for sql dialect
dbmsConnectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "spark", # any valid options - such as 'redshift', 'sql server', etc.
  pathToDriver = "/"
)

# Database parameters that are pre-filled in the written queries
# Use @-syntax if creating a template-sql at execution-time (e.g. "@cdmDatabaseSchema")
cdmDatabaseSchema <- "yourCdmSchema" # the fully qualified database schema name of the CDM
resultsDatabaseSchema <- "yourResultsSchema" # the fully qualified database schema name of the results schema (that you can write to)
writeTableName <- "dqdashboard_results"

sqlFolder <- "./results"
cdmSourceName <- "Your CDM Source" # a human readable name for your CDM source

sqlOnly <- TRUE
sqlOnlyUnionCount <- 100  # Number of check sqls to union in a single query. A smaller number gives more control and progress information, a higher number typically gives a higher performance.  
sqlOnlyIncrementalInsert <- TRUE # If FALSE, then pre v2.3.0 format.  If TRUE, then wraps check query in cte with all metadata and inserts into result table

verboseMode <- TRUE

cdmVersion <- "5.3" # version of your CDM
checkLevels <- c("TABLE", "FIELD", "CONCEPT")
tablesToExclude <- c()
checkNames <- c()

DataQualityDashboard::executeDqChecks(
  connectionDetails = dbmsConnectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  resultsDatabaseSchema = resultsDatabaseSchema,
  writeTableName = writeTableName,
  cdmSourceName = cdmSourceName,
  sqlOnly = sqlOnly,
  sqlOnlyUnionCount = sqlOnlyUnionCount,
  sqlOnlyIncrementalInsert = sqlOnlyIncrementalInsert,
  outputFolder = sqlFolder,
  checkLevels = checkLevels,
  verboseMode = verboseMode,
  cdmVersion = cdmVersion,
  tablesToExclude = tablesToExclude,
  checkNames = checkNames
)
