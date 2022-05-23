


# fill out the connection details -----------------------------------------------------------------------
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = 'postgresql', user = Sys.getenv('user'), 
                                                                password = Sys.getenv('pw'), server = 'testnode.arachnenetwork.com/synthea', 
                                                                port = '5441', pathToDriver='c:/jdbcDrivers')

cdmDatabaseSchema <- "CDM_531" # the fully qualified database schema name of the CDM
resultsDatabaseSchema <- "CDM_531" # the fully qualified database schema name of the results schema (that you can write to)
cdmSourceName <- "synthea" # a human readable name for your CDM source
cdmVersion <- "5.4" # the CDM version you are targetting. Currently supporst 5.2.2, 5.3.1, and 5.4

numThreads <- 4

# specify if you want to execute the queries or inspect them ------------------------------------------
sqlOnly <- FALSE # set to TRUE if you just want to get the SQL scripts and not actually run the queries

# where should the logs go? -------------------------------------------------------------------------
outputFolder <- "C:/Users/LuisAlaniz/Documents/synthea"

# logging type -------------------------------------------------------------------------------------
verboseMode <- TRUE # set to TRUE if you want to see activity written to the console

# write results to table? -----------------------------------------------------------------------
writeToTable <- TRUE # set to FALSE if you want to skip writing to results table

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

checkNames <- c() #Names can be found in inst/csv/OMOP_CDM_v5.3.1_Check_Desciptions.csv

# which CDM tables to exclude? ------------------------------------

tablesToExclude <- c() 

# run the job --------------------------------------------------------------------------------------
DataQualityDashboard::executeDqChecks(connectionDetails = connectionDetails, 
                                      cdmDatabaseSchema = cdmDatabaseSchema, 
                                      resultsDatabaseSchema = resultsDatabaseSchema,
                                      cdmSourceName = cdmSourceName, 
                                      numThreads = numThreads,
                                      sqlOnly = sqlOnly, 
                                      outputFolder = outputFolder,
                                      outputFile = paste0("results_", cdmSourceName, ".json"),
                                      verboseMode = verboseMode,
                                      writeToTable = writeToTable,
                                      checkLevels = checkLevels,
                                      tablesToExclude = tablesToExclude,
                                      checkNames = checkNames)


ParallelLogger::launchLogViewer(logFileName = file.path(outputFolder, 
                                                        sprintf("log_DqDashboard_%s.txt", cdmSourceName)))

# (OPTIONAL) if you want to write the JSON file to the results table separately -----------------------------
jsonFilePath <- file.path(outputFolder, paste0("results_", cdmSourceName, ".json")) # put the path to the outputted JSON file

DataQualityDashboard::writeJsonResultsToTable(connectionDetails = connectionDetails, 
                                              resultsDatabaseSchema = resultsDatabaseSchema, 
                                              jsonFilePath = jsonFilePath)

# View the Data Quality Dashboard using the integrated shiny application
DataQualityDashboard::viewDqDashboard(jsonFilePath)
