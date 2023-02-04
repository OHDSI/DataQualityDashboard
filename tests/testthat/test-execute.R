library(testthat)

test_that("listDqChecks works", {
  checks <- listDqChecks()
  expect_equal(length(checks), 4)
  expect_true(all(sapply(checks, is.data.frame)))
})

test_that("Execute a single DQ check on Synthea/Eunomia", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  expect_warning(
    results <- executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsDatabaseSchema = resultsDatabaseSchema,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = F
    ),
    regexp = "^Missing check names.*"
  )

  expect_true(nrow(results$CheckResults) > 1)
})

test_that("Execute all TABLE checks on Synthea/Eunomia", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  results <- executeDqChecks(
    connectionDetails = connectionDetailsEunomia,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = resultsDatabaseSchema,
    cdmSourceName = "Eunomia",
    checkLevels = "TABLE",
    outputFolder = outputFolder,
    writeToTable = F
  )

  expect_true(nrow(results$CheckResults) > 0)
})


test_that("Execute FIELD checks on Synthea/Eunomia", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  results <- executeDqChecks(
    connectionDetails = connectionDetailsEunomia,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = resultsDatabaseSchema,
    cdmSourceName = "Eunomia",
    checkLevels = "FIELD",
    outputFolder = outputFolder,
    writeToTable = F
  )
  expect_true(nrow(results$CheckResults) > 0)
})

test_that("Execute CONCEPT checks on Synthea/Eunomia", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))
  results <- executeDqChecks(
    connectionDetails = connectionDetailsEunomia,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = resultsDatabaseSchema,
    cdmSourceName = "Eunomia",
    checkLevels = "CONCEPT",
    conceptCheckThresholdLoc = system.file(
      "csv",
      "unittest_OMOP_CDMv5.3_Concept_Level.csv",
      package = "DataQualityDashboard"
    ),
    outputFolder = outputFolder,
    writeToTable = F
  )
  expect_true(nrow(results$CheckResults) > 0)
})


test_that("Execute a single DQ check on remote databases", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  dbTypes <- c(
    "oracle",
    "postgresql",
    "sql server"
  )

  for (dbType in dbTypes) {
    sysUser <- Sys.getenv(sprintf("CDM5_%s_USER", toupper(dbType)))
    sysPassword <- URLdecode(Sys.getenv(sprintf("CDM5_%s_PASSWORD", toupper(dbType))))
    sysServer <- Sys.getenv(sprintf("CDM5_%s_SERVER", toupper(dbType)))
    sysExtraSettings <- Sys.getenv(sprintf("CDM5_%s_EXTRA_SETTINGS", toupper(dbType)))
    if (sysUser != "" &
      sysPassword != "" &
      sysServer != "") {
      cdmDatabaseSchema <- Sys.getenv(sprintf("CDM5_%s_CDM_SCHEMA", toupper(dbType)))
      resultsDatabaseSchema <- Sys.getenv("CDM5_%s_OHDSI_SCHEMA", toupper(dbType))

      connectionDetails <- createConnectionDetails(
        dbms = dbType,
        user = sysUser,
        password = sysPassword,
        server = sysServer,
        extraSettings = sysExtraSettings,
        pathToDriver = jdbcDriverFolder
      )

      expect_warning(
        results <- executeDqChecks(
          connectionDetails = connectionDetails,
          cdmDatabaseSchema = cdmDatabaseSchema,
          resultsDatabaseSchema = resultsDatabaseSchema,
          cdmSourceName = "test",
          numThreads = 1,
          sqlOnly = FALSE,
          outputFolder = outputFolder,
          verboseMode = FALSE,
          writeToTable = FALSE,
          checkNames = "measurePersonCompleteness"
        ),
        regexp = "^Missing check names.*"
      )

      expect_true(nrow(results$CheckResults) > 0)
    }
  }
})

test_that("Check invalid cdm version", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  expect_error(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      resultsDatabaseSchema = resultsDatabaseSchema,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE,
      cdmVersion = "5.2.3.1"
    ),
    regexp = "^cdmVersion must contain a version of the form '5.X'"
  )
})

test_that("Write JSON results", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  expect_warning(
    results <- executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsDatabaseSchema = resultsDatabaseSchema,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    regexp = "^Missing check names.*"
  )

  jsonPath <- list.files(outputFolder, ".json", full.names = TRUE)
  csvPath <- file.path(outputFolder, "results.csv")
  writeJsonResultsToCsv(
    jsonPath = jsonPath,
    csvPath = csvPath
  )
  expect_true(file.exists(csvPath))

  DataQualityDashboard::writeJsonResultsToTable(
    connectionDetails = connectionDetailsEunomia,
    resultsDatabaseSchema = resultsDatabaseSchema,
    jsonFilePath = jsonPath,
    writeTableName = "dqd_results"
  )
  connection <- DatabaseConnector::connect(connectionDetailsEunomia)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  tableNames <- DatabaseConnector::getTableNames(connection = connection, databaseSchema = resultsDatabaseSchema)
  expect_true("dqd_results" %in% tolower(tableNames))
  DatabaseConnector::renderTranslateExecuteSql(connection, "DROP TABLE @database_schema.dqd_results;", database_schema = resultsDatabaseSchema)
})

test_that("Execute DQ checks and write to table", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))
  
  expect_warning(
    results <- executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsDatabaseSchema = resultsDatabaseSchema,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = TRUE,
      writeTableName = "dqd_results"
    ),
    regexp = "^Missing check names.*"
  )
  connection <- DatabaseConnector::connect(connectionDetailsEunomia)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  tableNames <- DatabaseConnector::getTableNames(connection = connection, databaseSchema = resultsDatabaseSchema)
  expect_true("dqd_results" %in% tolower(tableNames))
  DatabaseConnector::renderTranslateExecuteSql(connection, "DROP TABLE @database_schema.dqd_results;", database_schema = resultsDatabaseSchema)
})

test_that("Execute reEvaluateThresholds on Synthea/Eunomia", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  expect_warning(
    results <- executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsDatabaseSchema = resultsDatabaseSchema,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = F
    ),
    regexp = "^Missing check names.*"
  )

  jsonPath <- list.files(outputFolder, ".json", full.names = TRUE)

  results2 <- reEvaluateThresholds(
    jsonFilePath = jsonPath,
    outputFolder = outputFolder,
    outputFile = "reEvaluated.txt"
  )
  expect_is(results2, "list")
})
