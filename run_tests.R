install.packages("/Users/wvekeman/Code/DataQualityDashboard_2.0.5.tar.gz", repos = NULL, type = "source")
library('DataQualityDashboard')

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql", 
                                                                user = "honeur_admin", 
                                                                password = "honeur_admin", 
                                                                server = "localhost/OHDSI", 
                                                                port = "5444", 
                                                                extraSettings = "")

cdmDatabaseSchema <- "emmos" # the fully qualified database schema name of the CDM

resultsDatabaseSchema <- "results" # the fully qualified database schema name of the results schema (that you can write to)

vocabDatabaseSchema <- "omopcdm"

cdmSourceName <- "EMMOS" # a human readable name for your CDM source

numThreads <- 1

sqlOnly <- FALSE # set to TRUE if you just want to get the SQL scripts and not actually run the queries

outputFolder <- "output" # this folder will be created in your working directory. 

verboseMode <- TRUE # set to TRUE if you want to see activity written to the console

writeToTable <- FALSE # set to FALSE if you want to skip writing to a SQL table in the results schema

checkNames <-c()

checkLevels <- c("TABLE", "FIELD", "CONCEPT")
checkNames <- c('conventionSimilarity', 'followsConvention',"wrongDomain", 'checkUnit', 'checkAllowedValues', 'isStandardValidConcept','measureValueCompleteness', 'sourceValueCompleteness', 'plausibleTemporalAfter', 'plausibleDuringLife', 'measurePersonCompletenes', 'isRequired', 'treatmentLineOrder', 'periodOverlap')
checkNames <- c('checkTreatmentLineStart')
tablesToExclude <- c("cost", "payer_plan_period", "visit_detail","note_nlp","note" ) 

DataQualityDashboard::executeDqChecks(connectionDetails = connectionDetails, 
                                      cdmDatabaseSchema = cdmDatabaseSchema, 
                                      resultsDatabaseSchema = resultsDatabaseSchema,
                                      vocabDatabaseSchema = vocabDatabaseSchema,
                                      cdmSourceName = cdmSourceName, 
                                      numThreads = numThreads,
                                      sqlOnly = sqlOnly, 
                                      outputFolder = outputFolder, 
                                      verboseMode = verboseMode,
                                      writeToTable = writeToTable,
                                      checkLevels = checkLevels,
                                      tablesToExclude = tablesToExclude,
                                      checkNames = checkNames)

DataQualityDashboard::viewDqDashboard(jsonPath = file.path(getwd(), outputFolder, cdmSourceName, sprintf("results_%s.json", cdmSourceName)))
