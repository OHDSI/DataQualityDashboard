library(testthat)

test_that("Write JSON results", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  expect_warning(
    results <- executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
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

  # Test default behavior (3 separate tables with deprecation warning)
  expect_warning(
    DataQualityDashboard::writeJsonResultsToTable(
      connectionDetails = connectionDetailsEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      jsonFilePath = jsonPath,
      writeTableName = "dqd_json_results"
    ),
    "Writing to 3 separate tables by check level is deprecated"
  )
  connection <- DatabaseConnector::connect(connectionDetailsEunomia)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  tableNames <- DatabaseConnector::getTableNames(connection = connection, databaseSchema = resultsDatabaseSchemaEunomia)
  expect_true("dqd_json_results_table" %in% tolower(tableNames))
  DatabaseConnector::renderTranslateExecuteSql(connection, "DROP TABLE @database_schema.dqd_json_results_table;", database_schema = resultsDatabaseSchemaEunomia)
})

test_that("Write JSON results with singleTable parameter", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  expect_warning(
    results <- executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    regexp = "^Missing check names.*"
  )

  jsonPath <- list.files(outputFolder, ".json", full.names = TRUE)

  # Test singleTable = TRUE (new behavior)
  expect_warning(
    DataQualityDashboard::writeJsonResultsToTable(
      connectionDetails = connectionDetailsEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      jsonFilePath = jsonPath,
      writeTableName = "dqd_single_table",
      singleTable = TRUE
    ),
    NA
  )

  connection <- DatabaseConnector::connect(connectionDetailsEunomia)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  tableNames <- DatabaseConnector::getTableNames(connection = connection, databaseSchema = resultsDatabaseSchemaEunomia)
  expect_true("dqd_single_table" %in% tolower(tableNames))
  DatabaseConnector::renderTranslateExecuteSql(connection, "DROP TABLE @database_schema.dqd_single_table;", database_schema = resultsDatabaseSchemaEunomia)

  # Test singleTable = FALSE (old behavior with deprecation warning)
  # Since we only have table-level checks, only the table-level table will be created
  expect_warning(
    DataQualityDashboard::writeJsonResultsToTable(
      connectionDetails = connectionDetailsEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      jsonFilePath = jsonPath,
      writeTableName = "dqd_separate_tables",
      singleTable = FALSE
    ),
    "Writing to 3 separate tables by check level is deprecated"
  )

  tableNames <- DatabaseConnector::getTableNames(connection = connection, databaseSchema = resultsDatabaseSchemaEunomia)
  # Check that table-level table was created (only one that should exist for this test)
  expect_true("dqd_separate_tables_table" %in% tolower(tableNames))

  # Clean up
  DatabaseConnector::renderTranslateExecuteSql(connection, "DROP TABLE @database_schema.dqd_separate_tables_table;", database_schema = resultsDatabaseSchemaEunomia)
})
