library(testthat)

test_that("Write DB results to json", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))
  connectionDetailsEunomia <- Eunomia::getEunomiaConnectionDetails()
  cdmDatabaseSchemaEunomia <- "main"
  resultsDatabaseSchemaEunomia <- "main"

  results <- DataQualityDashboard::executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = TRUE,
      writeTableName = "dqdashboard_results"
  )


  connection <- DatabaseConnector::connect(connectionDetailsEunomia)
  tableNames <- DatabaseConnector::getTableNames(connection = connection, databaseSchema = resultsDatabaseSchemaEunomia)
  expect_true("dqdashboard_results" %in% tolower(tableNames))

  testExportFile <- "dq-result-test.json"

  DataQualityDashboard::writeDBResultsToJson(
    connection,
    connectionDetailsEunomia,
    resultsDatabaseSchemaEunomia,
    cdmDatabaseSchemaEunomia,
    "dqdashboard_results",
    outputFolder,
    testExportFile
    )

  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  expect_true(file.exists(file.path(outputFolder,testExportFile)))


})