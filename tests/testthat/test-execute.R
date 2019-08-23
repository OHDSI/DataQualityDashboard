library(testthat)

test_that("Execute DQ checks", {
  results <- executeDqChecks(connectionDetails = connectionDetails, 
                             cdmDatabaseSchema = cdmDatabaseSchema, 
                             resultsDatabaseSchema = resultsDatabaseSchema, 
                             cdmSourceName = "test", 
                             numThreads = 1, 
                             sqlOnly = FALSE, 
                             outputFolder = "output", 
                             verboseMode = FALSE, 
                             writeToTable = FALSE, 
                             checkLevels = c(), 
                             checkNames = c())
  
  expect_true(nrow(results$CheckResults) > 0)
})