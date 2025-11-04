library(testthat)

test_that("Camel correctly converted to snake and back", {
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
      outputFile = "foo.json",
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  jsonFilePath <- file.path(outputFolder, "foo.json")
  expect_warning(
    convertJsonResultsFileCase(jsonFilePath, writeToFile = FALSE, targetCase = "camel"),
    regexp = "^File is already in camelcase!"
  )
  snakeResults <- convertJsonResultsFileCase(jsonFilePath, writeToFile = TRUE, outputFolder, outputFile = "snake.json", targetCase = "snake")
  snakeNames <- c("NUM_VIOLATED_ROWS", "PCT_VIOLATED_ROWS", "NUM_DENOMINATOR_ROWS", "EXECUTION_TIME", "QUERY_TEXT", "CHECK_NAME", "CHECK_LEVEL", "CHECK_DESCRIPTION", "CDM_TABLE_NAME", "SQL_FILE", "CATEGORY", "CONTEXT", "checkId", "FAILED", "PASSED", "IS_ERROR", "NOT_APPLICABLE", "THRESHOLD_VALUE")


  expect_equal(length(snakeResults), 7)
  expect_true(setequal(names(snakeResults$CheckResults), snakeNames))

  snakeFilePath <- file.path(outputFolder, "snake.json")
  expect_warning(
    convertJsonResultsFileCase(snakeFilePath, writeToFile = FALSE, targetCase = "snake"),
    regexp = "^File is already in snakecase!"
  )
  camelResults <- convertJsonResultsFileCase(snakeFilePath, writeToFile = TRUE, outputFolder, targetCase = "camel")
  camelNames <- c("numViolatedRows", "pctViolatedRows", "numDenominatorRows", "executionTime", "queryText", "checkName", "checkLevel", "checkDescription", "cdmTableName", "sqlFile", "category", "context", "checkId", "failed", "passed", "isError", "notApplicable", "thresholdValue")
  camelFilePath <- file.path(outputFolder, "snake_camel.json")



  expect_equal(length(camelResults), 7)
  expect_true(setequal(names(camelResults$CheckResults), camelNames))
  expect_true(file.exists(camelFilePath))

  origJson <- jsonlite::toJSON(results)
  reconvertedJson <- jsonlite::toJSON(camelResults)
  expect_equal(origJson, reconvertedJson)
})

test_that("Invalid case throws error", {
  expect_error(
    convertJsonResultsFileCase("bar.json", writeToFile = FALSE, targetCase = "foo"),
    regexp = "^targetCase must be either 'camel' or 'snake'."
  )
})

test_that("Output folder required when writing to file", {
  expect_error(
    convertJsonResultsFileCase("bar.json", writeToFile = TRUE, targetCase = "camel"),
    regexp = "^You must specify an output folder if writing to file."
  )
})
