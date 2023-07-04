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
  
  DataQualityDashboard::writeJsonResultsToTable(
    connectionDetails = connectionDetailsEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    jsonFilePath = jsonPath,
    writeTableName = "dqd_results"
  )
  connection <- DatabaseConnector::connect(connectionDetailsEunomia)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  tableNames <- DatabaseConnector::getTableNames(connection = connection, databaseSchema = resultsDatabaseSchemaEunomia)
  expect_true("dqd_results" %in% tolower(tableNames))
  DatabaseConnector::renderTranslateExecuteSql(connection, "DROP TABLE @database_schema.dqd_results;", database_schema = resultsDatabaseSchemaEunomia)
})