
# fill out the connection details -----------------------------------------------------------------------
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "", user = "", 
                                                                password = "", server = "", 
                                                                port = "", extraSettings = "")

cdmDatabaseSchema <- "yourCdmSchema" # the fully qualified database schema name of the CDM
cdmSourceName <- "Your CDM Source" # a human readable name for your CDM source

# determine how many threads (concurrent SQL sessions) to use ----------------------------------------
numThreads <- 1 # on Redshift, 3 seems to work well

# specify if you want to execute the queries or inspect them ------------------------------------------
sqlOnly <- FALSE # set to TRUE if you just want to get the SQL scripts and not actually run the queries

# run the job --------------------------------------------------------------------------------------
DataQualityDashboard::execute(connectionDetails = connectionDetails, 
                              cdmDatabaseSchema = cdmDatabaseSchema, 
                              cdmSourceName = cdmSourceName, 
                              numThreads = numThreads,
                              sqlOnly = sqlOnly)