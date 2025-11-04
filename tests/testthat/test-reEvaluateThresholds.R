library(testthat)

test_that("Execute reEvaluateThresholds on Synthea/Eunomia", {
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

  jsonPath <- list.files(outputFolder, ".json", full.names = TRUE)

  results2 <- reEvaluateThresholds(
    jsonFilePath = jsonPath,
    outputFolder = outputFolder,
    outputFile = "reEvaluated.txt"
  )

  expect_type(results2, "list")
})
