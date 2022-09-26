#' This is an example of how to run DQD in sqlOnly mode
#' There are two main advantages of running DQD in  sqlOnly mode:
#' - Create queries locally, before sending to server. This allows for inspection of code before execution.
#' - Faster. With sqlOnlyUnionCount > 1 multiple checks can be executed in one query

library(DataQualityDashboard)
library(DatabaseConnector)

# ConnectionDetails object needed for sql dialect
dbmsConnectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "",
  pathToDriver = "/"
)

# Database parameters that are pre-filled in the written queries
# Use @-syntax if creating a template-sql at execution-time (e.g. "@cdmDatabaseSchema")
cdmDatabaseSchema <- ""
resultsDatabaseSchema <- ""
writeTableName <- "dqdashboard_results"

outputFolder <- "./results"
cdmSourceName <- ""

sqlOnly <- TRUE
sqlOnlyUnionCount <- 100  # Number of check sqls to union in a single query. A smaller number gives more control and progress information, a higher number typically gives a higher performance.  

verboseMode <- TRUE

cdmVersion <- "5.3.1"
checkLevels <- c("TABLE", "FIELD")  # Bug in rendering concept level checks
tablesToExclude <- c()
checkNames <- c()

# Run DQD. With sqlOnly=TRUE, this creates a sql file for each check type
t1 <- Sys.time()
DataQualityDashboard::executeDqChecks(
  connectionDetails = dbmsConnectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  resultsDatabaseSchema = resultsDatabaseSchema,
  writeTableName = writeTableName,
  cdmSourceName = cdmSourceName,
  sqlOnly = sqlOnly,
  sqlOnlyUnionCount = sqlOnlyUnionCount,
  outputFolder = outputFolder,
  checkLevels = checkLevels,
  verboseMode = verboseMode,
  cdmVersion = cdmVersion,
  tablesToExclude = tablesToExclude,
  checkNames = checkNames
)
t2 <- Sys.time()
print(t2-t1)


# (OPTIONAL) Execute queries against your database
# Note; this uses some non-exported DQD functions
library(DatabaseConnector)
cdmSourceName <- ""
sqlFolder <- "./results"
jsonOutputFolder <- sqlFolder
jsonOutputFile <- "sql_only_results.json"

dbms <- Sys.getenv("DBMS")
server <- Sys.getenv("DB_SERVER")
port <- Sys.getenv("DB_PORT")
user <- Sys.getenv("DB_USER")
password <- Sys.getenv("DB_PASSWORD")
pathToDriver <- Sys.getenv("PATH_TO_DRIVER")
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = dbms,
  server = server,
  port = port,
  user = user,
  password = password,
  pathToDriver = pathToDriver
)
t1 <- Sys.time()

c <- DatabaseConnector::connect(connectionDetails)

# Create results table
ddlFile <- file.path(outputFolder, "ddlDqdResults.sql")
ddl <- readChar(ddlFile, file.info(ddlFile)$size)
DatabaseConnector::executeSql(c, ddl)

# Run checks
sqlFiles <- Sys.glob(file.path(outputFolder, "*.sql"))
for (sqlFile in sqlFiles) {
  if (sqlFile == ddlFile) {
    next
  }
  print(sqlFile)
  sql <- readChar(sqlFile, file.info(sqlFile)$size)
  DatabaseConnector::executeSql(c, sql)
}

# Get results
checkResults <- DatabaseConnector::querySql(
  c,
  SqlRender::render(
    "SELECT * FROM @resultsDatabaseSchema.@writeTableName", 
    resultsDatabaseSchema=  resultsDatabaseSchema, 
    writeTableName = writeTableName
  )
)
DatabaseConnector::disconnect(c)

# Summarize overview
overview <- DataQualityDashboard:::.summarizeResults(checkResults = checkResults)

t2 <- Sys.time()
print(t2-t1)

# Create results object
result <- list(
  startTimestamp = Sys.time(), 
  endTimestamp = Sys.time(),
  executionTime = 0,
  CheckResults = checkResults, 
  Metadata = list(
    DQD_VERSION = as.character(packageVersion("DataQualityDashboard")),
    CDM_SOURCE_NAME = cdmSourceName
  ),
  Overview = overview
)

DataQualityDashboard:::.writeResultsToJson(result, jsonOutputFolder, jsonOutputFile)

DataQualityDashboard::viewDqDashboard(file.path(getwd(), jsonOutputFolder, jsonOutputFile))
