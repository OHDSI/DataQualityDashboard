library(testthat)

test_that("Execute reEvaluateThresholds on Synthea/Eunomia", {
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

  expect_type(results2, "list")
})