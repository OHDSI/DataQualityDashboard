library(testthat)

test_that("Write DB results to json", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))
  connectionDetailsEunomia <- Eunomia::getEunomiaConnectionDetails()
  cdmDatabaseSchemaEunomia <- "main"
  resultsDatabaseSchemaEunomia <- "main"
  writeTableName <- "dqd_db_results"

  expect_warning(
    results <- DataQualityDashboard::executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = TRUE,
      writeTableName = writeTableName
    ),
    regexp = "^Missing check names.*"
  )

  connection <- DatabaseConnector::connect(connectionDetailsEunomia)

  testExportFile <- "dq-result-test.json"

  DataQualityDashboard::writeDBResultsToJson(
    connection,
    resultsDatabaseSchemaEunomia,
    cdmDatabaseSchemaEunomia,
    writeTableName,
    outputFolder,
    testExportFile
  )

  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)

  # Check that file was exported properly
  expect_true(file.exists(file.path(outputFolder, testExportFile)))

  # Check that export length matches length of db table
  results <- jsonlite::fromJSON(file.path(outputFolder, testExportFile))
  tableRows <- DatabaseConnector::renderTranslateQuerySql(
    connection,
    sql = "select count(*) from @resultsDatabaseSchema.@writeTableName;",
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    writeTableName = writeTableName,
    snakeCaseToCamelCase = TRUE
  )
  expect_true(length(results$CheckResults) == tableRows)
})
