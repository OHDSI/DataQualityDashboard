library(testthat)

test_that("Write DB results to json", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))
  connectionDetailsEunomia <- Eunomia::getEunomiaConnectionDetails()
  cdmDatabaseSchemaEunomia <- "main"
  resultsDatabaseSchemaEunomia <- "main"
  writeTableName <- "dqd_db_results"

  # Suppress both DatabaseConnector warnings and Missing check names warning
  results <- withCallingHandlers(
    DataQualityDashboard::executeDqChecks(
      connectionDetails = connectionDetailsEunomia,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = "measurePersonCompleteness",
      outputFolder = outputFolder,
      writeToTable = TRUE,
      writeTableName = writeTableName
    ),
    warning = function(w) {
      msg <- conditionMessage(w)
      # Suppress warnings about converting logical columns and missing check names
      if (grepl("Converting to numeric", msg) || grepl("Missing check names", msg)) {
        invokeRestart("muffleWarning")
      }
    }
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
