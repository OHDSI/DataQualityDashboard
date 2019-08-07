
# fill out the connection details -----------------------------------------------------------------------
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "", user = "", 
                                                                password = "", server = "", 
                                                                port = "", extraSettings = "")

cdmDatabaseSchema <- "yourCdmSchema" # the fully qualified database schema name of the CDM
resultsDatabaseSchema <- "yourResultsSchema" # the fully qualified database schema name of the results schema (that you can write to)
cdmSourceName <- "Your CDM Source" # a human readable name for your CDM source

# determine how many threads (concurrent SQL sessions) to use ----------------------------------------
numThreads <- 1 # on Redshift, 3 seems to work well

# specify if you want to execute the queries or inspect them ------------------------------------------
sqlOnly <- FALSE # set to TRUE if you just want to get the SQL scripts and not actually run the queries

# where should the logs go? -------------------------------------------------------------------------
outputFolder <- "output"

# logging type -------------------------------------------------------------------------------------
verboseMode <- FALSE # set to TRUE if you want to see activity written to the console

# write results to table? -----------------------------------------------------------------------
writeToTable <- TRUE # set to FALSE if you want to skip writing to results table

# run the job --------------------------------------------------------------------------------------
DataQualityDashboard::execute(connectionDetails = connectionDetails, 
                              cdmDatabaseSchema = cdmDatabaseSchema, 
                              resultsDatabaseSchema = resultsDatabaseSchema,
                              cdmSourceName = cdmSourceName, 
                              numThreads = numThreads,
                              sqlOnly = sqlOnly, 
                              outputFolder = outputFolder, 
                              verboseMode = verboseMode,
                              writeToTable = writeToTable)
