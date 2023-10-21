library(testthat)

test_that("Write DB results to json", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))
  connectionDetailsEunomia <- Eunomia::getEunomiaConnectionDetails()
  cdmDatabaseSchemaEunomia <- "main"
  resultsDatabaseSchemaEunomia <- "main"
  writeTableName <- "dqdashboard_results"

  results <- DataQualityDashboard::executeDqChecks(
    connectionDetails = connectionDetailsEunomia,
    cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    cdmSourceName = "Eunomia",
    checkNames = "measurePersonCompleteness",
    outputFolder = outputFolder,
    writeToTable = TRUE,
    writeTableName = writeTableName
  )


  connection <- DatabaseConnector::connect(connectionDetailsEunomia)

  testExportFile <- "dq-result-test.json"

  DataQualityDashboard::writeDBResultsToJson(
    connection,
    connectionDetailsEunomia,
    resultsDatabaseSchemaEunomia,
    cdmDatabaseSchemaEunomia,
    writeTableName,
    outputFolder,
    testExportFile
  )

  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)

  # Check that file was exported properly
  expect_true(file.exists(file.path(outputFolder,testExportFile)))

  # Check that export length matches length of db table
  results <- jsonlite::fromJSON(file.path(outputFolder,testExportFile))
  table_rows <- DatabaseConnector::renderTranslateQuerySql(
    connection,
    sql = "select count(*) from @resultsDatabaseSchema.@writeTableName;",
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    writeTableName = writeTableName,
    targetDialect = connectionDetailsEunomia$dbms,
    snakeCaseToCamelCase = TRUE
  )
  expect_true(length(results$CheckResults) == table_rows)

})