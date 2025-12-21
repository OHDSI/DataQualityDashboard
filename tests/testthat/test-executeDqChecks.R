library(testthat)
testthat::local_edition(3)

test_that("Execute a single DQ check on Synthea/Eunomia", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  withCallingHandlers(
    results <- executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  expect_true(nrow(results$CheckResults) > 1)
})

test_that("Execute all TABLE checks on Synthea/Eunomia", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkLevels = "TABLE",
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  expect_true(nrow(results$CheckResults) > 0)
})

test_that("Execute FIELD checks on Synthea/Eunomia", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkLevels = "FIELD",
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message) || grepl("^DEPRECATION WARNING", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )
  expect_true(nrow(results$CheckResults) > 0)
})

test_that("Execute CONCEPT checks on Synthea/Eunomia", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))
  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkLevels = "CONCEPT",
      conceptCheckThresholdLoc = system.file(
        "csv",
        "unittest_OMOP_CDMv5.3_Concept_Level.csv",
        package = "DataQualityDashboard"
      ),
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message) || grepl("^DEPRECATION WARNING", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )
  expect_true(nrow(results$CheckResults) > 0)
})

test_that("Execute observation period overlap check", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  # First, run the check on clean data (should pass)
  resultsClean <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomiaOverlap,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = c("measureObservationPeriodOverlap"),
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  expect_true(nrow(resultsClean$CheckResults) > 0)

  # Get the result for the observation period overlap check
  overlapResultClean <- resultsClean$CheckResults[
    resultsClean$CheckResults$checkName == "measureObservationPeriodOverlap",
  ]

  expect_true(nrow(overlapResultClean) == 1)

  # Now create overlapping observation periods to test the failure scenario
  connection <- DatabaseConnector::connect(connectionDetailsEunomiaOverlap)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)

  # Insert overlapping observation periods for a test person
  # First, get an existing person_id
  personId <- DatabaseConnector::querySql(connection, "SELECT person_id FROM observation_period LIMIT 1;")[1, 1]

  # Insert overlapping observation periods
  DatabaseConnector::renderTranslateExecuteSql(connection,
    "INSERT INTO observation_period (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id)
     VALUES
     (999999, @person_id, strftime('%s', '2020-01-01'), strftime('%s', '2020-06-30'), 44814724),
     (999998, @person_id, strftime('%s', '2020-04-01'), strftime('%s', '2020-12-31'), 44814724);",
    person_id = personId
  )

  # Run the check again with overlapping data (should fail)
  resultsOverlap <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomiaOverlap,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = c("measureObservationPeriodOverlap"),
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  expect_true(nrow(resultsOverlap$CheckResults) > 0)

  # Get the result for the observation period overlap check with overlapping data
  overlapResultOverlap <- resultsOverlap$CheckResults[
    resultsOverlap$CheckResults$checkName == "measureObservationPeriodOverlap",
  ]

  expect_true(nrow(overlapResultOverlap) == 1)

  # Verify that the check detected the overlap (should have violated rows)
  expect_true(overlapResultOverlap$numViolatedRows > 0)
  expect_true(overlapResultOverlap$pctViolatedRows > 0)

  # Verify that the clean data had no violations
  expect_true(overlapResultClean$numViolatedRows == 0)
  expect_true(overlapResultClean$pctViolatedRows == 0)

  # Clean up the overlapping data
  DatabaseConnector::renderTranslateExecuteSql(
    connection,
    "DELETE FROM observation_period WHERE observation_period_id IN (999999, 999998);"
  )

  # Now test back-to-back observation periods
  DatabaseConnector::renderTranslateExecuteSql(connection,
    "INSERT INTO observation_period (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id)
     VALUES
     (999997, @person_id, strftime('%s', '2020-01-01'), strftime('%s', '2020-06-30'), 44814724),
     (999996, @person_id, strftime('%s', '2020-07-01'), strftime('%s', '2020-12-31'), 44814724);",
    person_id = personId
  )

  # Run the check again with back-to-back data (should fail)
  resultsBackToBack <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomiaOverlap,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = c("measureObservationPeriodOverlap"),
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  expect_true(nrow(resultsBackToBack$CheckResults) > 0)

  # Get the result for the observation period overlap check with back-to-back data
  overlapResultBackToBack <- resultsBackToBack$CheckResults[
    resultsBackToBack$CheckResults$checkName == "measureObservationPeriodOverlap",
  ]

  expect_true(nrow(overlapResultBackToBack) == 1)

  # Verify that the check detected the back-to-back periods (should have violated rows)
  expect_true(overlapResultBackToBack$numViolatedRows > 0)
  expect_true(overlapResultBackToBack$pctViolatedRows > 0)

  # Clean up the back-to-back data
  DatabaseConnector::renderTranslateExecuteSql(
    connection,
    "DELETE FROM observation_period WHERE observation_period_id IN (999997, 999996);"
  )
})

test_that("Execute a single DQ check on a cohort in Synthea/Eunomia", {
  # simulating cohort table entries using observation period data
  connection <- DatabaseConnector::connect(connectionDetailsEunomia)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  fakeCohortId <- 123
  DatabaseConnector::renderTranslateExecuteSql(connection,
    "INSERT INTO @results_schema.cohort SELECT @cohort_id, person_id, observation_period_start_date, observation_period_end_date FROM @cdm_schema.observation_period LIMIT 10;",
    results_schema = resultsDatabaseSchemaEunomia,
    cohort_id = fakeCohortId,
    cdm_schema = cdmDatabaseSchemaEunomia
  )

  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  withCallingHandlers(
    results <- executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE,
      cohortTableName = "cohort",
      cohortDefinitionId = fakeCohortId
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  expect_true(nrow(results$CheckResults) > 1)
  DatabaseConnector::renderTranslateExecuteSql(connection,
    "DELETE FROM @results_schema.cohort WHERE cohort_definition_id = @cohort_id",
    results_schema = resultsDatabaseSchemaEunomia,
    cohort_id = fakeCohortId
  )
})

test_that("Execute a single DQ check on remote databases", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  dbTypes <- c(
    "oracle",
    "postgresql",
    "sql server",
    "redshift",
    "iris",
    "snowflake",
    "spark",
    "bigquery"
  )

  for (dbType in dbTypes) {
    print(sprintf("Processing database type: %s", dbType))
    
    if (dbType %in% c("oracle",
                      "postgresql",
                      "sql server",
                      "redshift",
                      "spark")) {
      cdmPattern <- "CDM5"
      if (dbType != "spark") {
        cdmSchemaPattern <- "CDM54"
      } else {
        cdmSchemaPattern <- "CDM"
      }
    } else if (dbType %in% c("iris",
                             "snowflake",
                             "bigquery")) {
      cdmPattern <- "CDM"
      if (dbType != "snowflake") {
        cdmSchemaPattern <- "CDM"
      } else {
        cdmSchemaPattern <- "CDM53"
      }
    }
    
    userVarName <- sprintf("%s_%s_USER", cdmPattern, toupper(gsub(" ", "_", dbType)))
    passwordVarName <- sprintf("%s_%s_PASSWORD", cdmPattern, toupper(gsub(" ", "_", dbType)))
    serverVarName <- sprintf("%s_%s_SERVER", cdmPattern, toupper(gsub(" ", "_", dbType)))
    
    sysUser <- Sys.getenv(userVarName)
    sysPassword <- URLdecode(Sys.getenv(passwordVarName))
    sysServer <- Sys.getenv(serverVarName)
    
    if (sysServer == "") {
      sysConnectionString <- Sys.getenv(sprintf("%s_%s_CONNECTION_STRING", cdmPattern, toupper(gsub(" ", "_", dbType))))
    } else {
      sysConnectionString <- ""
    }
    
    if (sysUser != "" &
      sysPassword != "" &
      (sysServer != "" | sysConnectionString != "")) {
      print(sprintf("Connection details found for %s, proceeding...", dbType))
      
      cdmDatabaseSchema <- Sys.getenv(sprintf("%s_%s_%s_SCHEMA", cdmPattern, toupper(gsub(" ", "_", dbType)), cdmSchemaPattern))
      resultsDatabaseSchema <- Sys.getenv(sprintf("%s_%s_OHDSI_SCHEMA", cdmPattern, toupper(gsub(" ", "_", dbType))))

      connectionDetails <- DatabaseConnector::createConnectionDetails(
        dbms = dbType,
        user = sysUser,
        password = sysPassword,
        server = sysServer,
        connectionString = sysConnectionString,
        pathToDriver = jdbcDriverFolder
      )

      # Verify connection before attempting to run checks
      connectionOk <- tryCatch({
        verifyConnection(connectionDetails)
        TRUE
      }, error = function(e) {
        warning(sprintf("Cannot connect to %s database: %s", dbType, e$message))
        FALSE
      })

      if (!connectionOk) {
        print(sprintf("Skipping %s due to connection failure, continuing to next database...", dbType))
        next
      }

      print(sprintf("Connection verified for %s, running checks...", dbType))

      # Run the checks
      checkOk <- tryCatch({
        results <- withCallingHandlers(
          executeDqChecks(
            connectionDetails = connectionDetails,
            cdmDatabaseSchema = cdmDatabaseSchema,
            resultsDatabaseSchema = resultsDatabaseSchema,
            cdmSourceName = "test",
            numThreads = 1,
            sqlOnly = FALSE,
            outputFolder = outputFolder,
            verboseMode = FALSE,
            writeToTable = FALSE,
            checkNames = "measurePersonCompleteness",
            cdmVersion = "5.4"
          ),
          warning = function(w) {
            if (grepl("^Missing check names", w$message)) {
              invokeRestart("muffleWarning")
            }
          }
        )
        expect_true(nrow(results$CheckResults) > 0)
        TRUE
      }, error = function(e) {
        if (grepl("Connection reset|Communication link failure|SocketException", e$message, ignore.case = TRUE)) {
          warning(sprintf("Connection error on %s: %s", dbType, e$message))
          FALSE
        } else {
          # For non-connection errors, fail the test
          stop(e)
        }
      })

      if (!checkOk) {
        print(sprintf("Skipping %s due to check execution failure, continuing to next database...", dbType))
        next
      }
      
      print(sprintf("Successfully completed checks for %s", dbType))
    } else {
      print(sprintf("No connection details found for %s, skipping...", dbType))
    }
  }
})

test_that("Check invalid cdm version", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  expect_error(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE,
      cdmVersion = "5.2.3.1"
    ),
    regexp = "^cdmVersion must contain a version of the form '5.X'"
  )
})

test_that("Execute DQ checks and write to table", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  withCallingHandlers(
    results <- executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = TRUE,
      writeTableName = "dqd_results"
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message) || grepl("Column.*is of type.*logical.*but this is not supported", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )
  connection <- DatabaseConnector::connect(connectionDetailsEunomia)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  tableNames <- DatabaseConnector::getTableNames(connection = connection, databaseSchema = resultsDatabaseSchemaEunomia)
  expect_true("dqd_results" %in% tolower(tableNames))
  DatabaseConnector::renderTranslateExecuteSql(connection, "DROP TABLE @database_schema.dqd_results;", database_schema = resultsDatabaseSchemaEunomia)
})

test_that("Execute DQ checks using sqlOnly=TRUE and sqlOnlyUnionCount=4 and sqlOnlyIncrementalInsert=TRUE", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))
  sqlOnlyConnectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sql server", pathToDriver = "/")

  withCallingHandlers(
    results <- executeDqChecks(
      connectionDetails = sqlOnlyConnectionDetails,
      cdmDatabaseSchema = "@yourCdmSchema",
      resultsDatabaseSchema = "@yourResultsSchema",
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE,
      sqlOnly = TRUE,
      sqlOnlyUnionCount = 4,
      sqlOnlyIncrementalInsert = TRUE,
      writeTableName = "dqdashboard_results"
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )
  expect_true("ddlDqdResults.sql" %in% list.files(outputFolder))
  dqdSqlFile <- "TABLE_measurePersonCompleteness.sql"
  expect_true(dqdSqlFile %in% list.files(outputFolder))

  dqdSqlFilePath <- file.path(outputFolder, dqdSqlFile)
  expect_snapshot(cat(SqlRender::readSql(dqdSqlFilePath)))
})

test_that("Execute DQ checks using sqlOnly=TRUE and sqlOnlyUnionCount=1 and sqlOnlyIncrementalInsert=TRUE", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))
  sqlOnlyConnectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sql server", pathToDriver = "/")

  withCallingHandlers(
    results <- executeDqChecks(
      connectionDetails = sqlOnlyConnectionDetails,
      cdmDatabaseSchema = "@yourCdmSchema",
      resultsDatabaseSchema = "@yourResultsSchema",
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE,
      sqlOnly = TRUE,
      sqlOnlyUnionCount = 1,
      sqlOnlyIncrementalInsert = TRUE,
      writeTableName = "dqdashboard_results"
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )
  expect_true("ddlDqdResults.sql" %in% list.files(outputFolder))
  dqdSqlFile <- "TABLE_measurePersonCompleteness.sql"
  expect_true(dqdSqlFile %in% list.files(outputFolder))

  dqdSqlFilePath <- file.path(outputFolder, dqdSqlFile)
  expect_snapshot(cat(SqlRender::readSql(dqdSqlFilePath)))
})

test_that("Execute DQ checks using sqlOnly=TRUE and sqlOnlyUnionCount=1 and sqlOnlyIncrementalInsert=FALSE (the behavior in version <= 2.2.0)", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))
  sqlOnlyConnectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sql server", pathToDriver = "/")

  withCallingHandlers(
    results <- executeDqChecks(
      connectionDetails = sqlOnlyConnectionDetails,
      cdmDatabaseSchema = "@yourCdmSchema",
      resultsDatabaseSchema = "@yourResultsSchema",
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE,
      sqlOnly = TRUE,
      sqlOnlyUnionCount = 1,
      sqlOnlyIncrementalInsert = FALSE,
      writeTableName = "dqdashboard_results"
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )
  expect_true("ddlDqdResults.sql" %in% list.files(outputFolder))
  dqdSqlFile <- "measurePersonCompleteness.sql"
  expect_true(dqdSqlFile %in% list.files(outputFolder))

  dqdSqlFilePath <- file.path(outputFolder, dqdSqlFile)
  expect_snapshot(cat(SqlRender::readSql(dqdSqlFilePath)))
})

test_that("Incremental insert SQL is valid.", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  withCallingHandlers(
    results <- executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE,
      sqlOnly = TRUE,
      sqlOnlyUnionCount = 4,
      sqlOnlyIncrementalInsert = TRUE,
      writeTableName = "dqd_results"
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  ddlSqlFile <- file.path(outputFolder, "ddlDqdResults.sql")
  ddlSql <- SqlRender::readSql(ddlSqlFile)
  checkSqlFile <- file.path(outputFolder, "TABLE_measurePersonCompleteness.sql")
  checkSql <- SqlRender::readSql(checkSqlFile)

  connection <- DatabaseConnector::connect(connectionDetailsEunomia)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  DatabaseConnector::executeSql(connection = connection, sql = ddlSql)
  DatabaseConnector::executeSql(connection = connection, sql = checkSql)

  checkResults <- DatabaseConnector::renderTranslateQuerySql(connection, "SELECT * FROM @database_schema.dqd_results;", database_schema = resultsDatabaseSchemaEunomia)
  expect_equal(nrow(checkResults), 16)

  DatabaseConnector::renderTranslateExecuteSql(connection, "DROP TABLE @database_schema.dqd_results;", database_schema = resultsDatabaseSchemaEunomia)
})

test_that("Multiple cdm_source rows triggers warning.", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  connectionDetailsEunomiaCS <- Eunomia::getEunomiaConnectionDetails()
  connection <- DatabaseConnector::connect(connectionDetailsEunomiaCS)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  DatabaseConnector::renderTranslateExecuteSql(connection, "INSERT INTO @database_schema.cdm_source VALUES ('foo',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);", database_schema = cdmDatabaseSchemaEunomia)

  w <- capture_warnings(
    results <- executeDqChecks(
      connectionDetails = connectionDetailsEunomiaCS,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE
    )
  )

  expect_match(w, "Missing check names", all = FALSE)
  expect_match(w, "The cdm_source table has", all = FALSE)

  expect_true(nrow(results$CheckResults) > 1)
})

test_that("Execute checks on Synthea/Eunomia to test new variable executionTimeSeconds", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))
  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      conceptCheckThresholdLoc = system.file(
        "csv",
        "unittest_OMOP_CDMv5.3_Concept_Level.csv",
        package = "DataQualityDashboard"
      ),
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )
  expect_true(is.numeric(results$executionTimeSeconds))
})


test_that("checkNames are filtered by checkSeverity", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkSeverity = "fatal",
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  expectedCheckNames <- c(
    "cdmTable", "cdmField", "isRequired", "cdmDatatype",
    "isPrimaryKey", "isForeignKey", "measureObservationPeriodOverlap"
  )
  expect_true(all(results$CheckResults$checkName %in% expectedCheckNames))
})

test_that("Execute a single DQ check on DuckDB", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  # Get Eunomia database file in DuckDB format
  eunomiaDbPath <- Eunomia::getDatabaseFile(
    datasetName = "GiBleed",
    dbms = "duckdb"
  )

  # Create DuckDB connection details using the Eunomia database file
  duckdbConnectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = "duckdb",
    server = eunomiaDbPath
  )

  withCallingHandlers(
    results <- executeDqChecks(
      connectionDetails = duckdbConnectionDetails,
      cdmDatabaseSchema = "main",
      resultsDatabaseSchema = "main",
      cdmSourceName = "DuckDB Test",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  expect_true(nrow(results$CheckResults) > 0)
})
