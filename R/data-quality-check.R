library(DatabaseConnector)
library(SqlRender)
library(magrittr)


dataQualityCheck <- function(cdm_dataType,
                             cdm_server,
                             cdm_port,
                             cdm_dataBaseSchema,
                             cdm_user,
                             cdm_password,
                             scanId,
                             threadCount,
                             cdmSourceName,
                             dqd_dataType,
                             dqd_server,
                             dqd_port,
                             dqd_dataBaseSchema,
                             dqd_user,
                             dqd_password,
                             username) {
  print("Starting Data Quality Check process..")

  Sys.setenv('DATABASECONNECTOR_JAR_FOLDER' = '~/jdbcDrivers')

  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = cdm_dataType,
                                                                  user = cdm_user,
                                                                  password = cdm_password,
                                                                  server = cdm_server,
                                                                  port = cdm_port,
                                                                  extraSettings = "")
  resultsDatabaseSchema <- "" # the fully qualified database schema name of the results schema (that you can write to)

  # determine how many threads (concurrent SQL sessions) to use ----------------------------------------
  numThreads <- threadCount # on Redshift, 3 seems to work well

  # specify if you want to execute the queries or inspect them ------------------------------------------
  sqlOnly <- FALSE # set to TRUE if you just want to get the SQL scripts and not actually run the queries

  # where should the logs go? -------------------------------------------------------------------------
  outputFolder <- file.path("output", username)

  # logging type -------------------------------------------------------------------------------------
  verboseMode <- FALSE # set to TRUE if you want to see activity written to the console

  # write results to table? ------------------------------------------------------------------------------
  writeToTable <- FALSE # set to FALSE if you want to skip writing to a SQL table in the results schema

  # which DQ check levels to run -------------------------------------------------------------------
  checkLevels <- c("TABLE", "FIELD", "CONCEPT")

  # which DQ checks to run? ------------------------------------
  checkNames <- c() # Names can be found in inst/csv/OMOP_CDM_v5.3.1_Check_Desciptions.csv

  print("Creating databae manager...")
  dqdDataBaseManager <- createDqdDatabaseManager(scanId = scanId,
                                                 dataType = dqd_dataType,
                                                 server = dqd_server,
                                                 port = dqd_port,
                                                 schema = dqd_dataBaseSchema,
                                                 dbUsername = dqd_user,
                                                 password = dqd_password)

  result <- executeDqChecks(connectionDetails = connectionDetails,
                            cdmDatabaseSchema = cdm_dataBaseSchema,
                            resultsDatabaseSchema = resultsDatabaseSchema,
                            cdmSourceName = cdmSourceName,
                            numThreads = numThreads,
                            sqlOnly = sqlOnly,
                            outputFolder = outputFolder,
                            verboseMode = verboseMode,
                            writeToTable = writeToTable,
                            checkLevels = checkLevels,
                            checkNames = checkNames,
                            logger = dqdDataBaseManager$logger,
                            interruptor = dqdDataBaseManager$interruptor)
  jsonResult <- jsonlite::toJSON(result)
  print("Data Quality Check process finished!")

  return(jsonResult)
}
