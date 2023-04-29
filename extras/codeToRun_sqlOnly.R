#' This is an example of how to run DQD in sqlOnly mode
#' There are two main advantages of running DQD in  sqlOnly mode:
#' - Create queries locally, before sending to server. This allows for inspection of code before execution.
#' - Faster. With sqlOnlyUnionCount > 1 multiple checks can be executed in one query

library(DataQualityDashboard)

# ConnectionDetails object needed for sql dialect
dbmsConnectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "",
  pathToDriver = "/"
)

# Database parameters that are pre-filled in the written queries
# Use @-syntax if creating a template-sql at execution-time (e.g. "@cdmDatabaseSchema")
cdmDatabaseSchema <- ""       # the fully qualified database schema name of the CDM
resultsDatabaseSchema <- ""   # the fully qualified database schema name of the results schema (that you can write to)
writeTableName <- "dqdashboard_results"

sqlFolder <- "./results"
cdmSourceName <- ""

sqlOnly <- TRUE
sqlOnlyUnionCount <- 100  # Number of check sqls to union in a single query. A smaller number gives more control and progress information, a higher number typically gives a higher performance.  

verboseMode <- TRUE

cdmVersion <- "5.3"
checkLevels <- c("TABLE", "FIELD", "CONCEPT")
tablesToExclude <- c()
checkNames <- c()

# Run DQD with sqlOnly=TRUE. This will create a sql file for each check type in the output folder
DataQualityDashboard::executeDqChecks(
  connectionDetails = dbmsConnectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  resultsDatabaseSchema = resultsDatabaseSchema,
  writeTableName = writeTableName,
  cdmSourceName = cdmSourceName,
  sqlOnly = sqlOnly,
  sqlOnlyUnionCount = sqlOnlyUnionCount,
  outputFolder = sqlFolder,
  checkLevels = checkLevels,
  verboseMode = verboseMode,
  cdmVersion = cdmVersion,
  tablesToExclude = tablesToExclude,
  checkNames = checkNames
)
