library(DatabaseConnector)
library(SqlRender)

dataQualityCheck <- function(dataType, server, port, dataBaseSchema, user, password, wsUserId, threadCount) {
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dataType,
                                                                  user = user,
                                                                  password = password,
                                                                  server = server,
                                                                  port = port,
                                                                  extraSettings = "")

  cdmDatabaseSchema <- dataBaseSchema # the fully qualified database schema name of the CDM
  resultsDatabaseSchema <- "" # the fully qualified database schema name of the results schema (that you can write to)
  cdmSourceName <- "" # a human readable name for your CDM source

  # determine how many threads (concurrent SQL sessions) to use ----------------------------------------
  numThreads <- threadCount # on Redshift, 3 seems to work well

  # specify if you want to execute the queries or inspect them ------------------------------------------
  sqlOnly <- FALSE # set to TRUE if you just want to get the SQL scripts and not actually run the queries

  # where should the logs go? -------------------------------------------------------------------------
  outputFolder <- "output"

  # logging type -------------------------------------------------------------------------------------
  verboseMode <- FALSE # set to TRUE if you want to see activity written to the console

  # write results to table? ------------------------------------------------------------------------------
  writeToTable <- FALSE # set to FALSE if you want to skip writing to a SQL table in the results schema

  # which DQ check levels to run -------------------------------------------------------------------
  checkLevels <- c("TABLE", "FIELD", "CONCEPT")

  # which DQ checks to run? ------------------------------------
  checkNames <- c() # Names can be found in inst/csv/OMOP_CDM_v5.3.1_Check_Desciptions.csv

  # which CDM tables to exclude? ------------------------------------
  tablesToExclude <- c()

  messageSender <- createMessageSender(wsUserId)

  messageSender$connect()

  result <- executeDqChecks(connectionDetails = connectionDetails,
                            cdmDatabaseSchema = cdmDatabaseSchema,
                            resultsDatabaseSchema = resultsDatabaseSchema,
                            cdmSourceName = cdmSourceName,
                            numThreads = numThreads,
                            sqlOnly = sqlOnly,
                            outputFolder = outputFolder,
                            verboseMode = verboseMode,
                            writeToTable = writeToTable,
                            checkLevels = checkLevels,
                            tablesToExclude = tablesToExclude,
                            checkNames = checkNames,
                            messageSender = messageSender)

  messageSender$close()

  jsonResult <- resultToJson(result)

  writeJsonResultToFile(jsonResult, outputFolder, cdmSourceName)

  return(jsonResult)
}
