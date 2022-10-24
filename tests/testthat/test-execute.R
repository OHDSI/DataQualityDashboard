library(testthat)

jdbcDriverFolder <- tempfile("jdbcDrivers")
DatabaseConnector::downloadJdbcDrivers("postgresql", pathToDriver = jdbcDriverFolder)
DatabaseConnector::downloadJdbcDrivers("sql server", pathToDriver = jdbcDriverFolder)
DatabaseConnector::downloadJdbcDrivers("oracle", pathToDriver = jdbcDriverFolder)


test_that("listDqChecks works", {
  checks <- listDqChecks()
  expect_equal(length(checks), 4)
  expect_true(all(sapply(checks, is.data.frame)))
})

test_that("Execute a single DQ check on Synthea/Eunomia", {
  results <- executeDqChecks(connectionDetails = Eunomia::getEunomiaConnectionDetails(),
                             cdmDatabaseSchema = "main",
                             resultsDatabaseSchema = "temp",
                             cdmSourceName = "Eunomia",
                             checkNames = "measurePersonCompleteness",
                             outputFolder = tempdir(),
                             writeToTable = F)

  expect_true(nrow(results$CheckResults) > 1)
})

test_that("Execute all TABLE checks on Synthea/Eunomia", {
  results <- executeDqChecks(connectionDetails = Eunomia::getEunomiaConnectionDetails(),
                             cdmDatabaseSchema = "main",
                             resultsDatabaseSchema = "temp",
                             cdmSourceName = "Eunomia",
                             checkLevels = "TABLE",
                             outputFolder = tempdir(),
                             writeToTable = F)

  expect_true(nrow(results$CheckResults) > 0)
})


test_that("Execute FIELD checks on Synthea/Eunomia", {
  results <- executeDqChecks(connectionDetails = Eunomia::getEunomiaConnectionDetails(),
                             cdmDatabaseSchema = "main",
                             resultsDatabaseSchema = "temp",
                             cdmSourceName = "Eunomia",
                             checkLevels = "FIELD",
                             outputFolder = tempdir(),
                             writeToTable = F)

  expect_true(nrow(results$CheckResults) > 0)
})

# This test takes a long time to run
# test_that("Execute CONCEPT checks on Synthea/Eunomia", {
#   results <- executeDqChecks(connectionDetails = Eunomia::getEunomiaConnectionDetails(),
#                              cdmDatabaseSchema = "main",
#                              resultsDatabaseSchema = "temp",
#                              cdmSourceName = "Eunomia",
#                              checkLevels = "CONCEPT",
#                              outputFolder = tempdir(),
#                              writeToTable = F)
# 
#   expect_true(nrow(results$CheckResults) > 0)
# })

test_that("Execute a single DQ check on remote databases", {

  dbTypes = c("oracle",
              "postgresql",
              "sql server")

  for (dbType in dbTypes) {
    sysUser <- Sys.getenv(sprintf("CDM5_%s_USER", toupper(dbType)))
    sysPassword <- URLdecode(Sys.getenv(sprintf("CDM5_%s_PASSWORD", toupper(dbType))))
    sysServer <- Sys.getenv(sprintf("CDM5_%s_SERVER", toupper(dbType)))
    sysExtraSettings <- Sys.getenv(sprintf("CDM5_%s_EXTRA_SETTINGS", toupper(dbType)))
    if (sysUser != "" &
        sysPassword != "" &
        sysServer != "") {
      cdmDatabaseSchema <- Sys.getenv(sprintf("CDM5_%s_CDM_SCHEMA", toupper(dbType)))
      resultsDatabaseSchema <- Sys.getenv("CDM5_%s_OHDSI_SCHEMA", toupper(dbType))

      connectionDetails <- createConnectionDetails(dbms = dbType,
                                         user = sysUser,
                                         password = sysPassword,
                                         server = sysServer,
                                         extraSettings = sysExtraSettings,
                                         pathToDriver = jdbcDriverFolder)

      results <- executeDqChecks(connectionDetails = connectionDetails,
                                 cdmDatabaseSchema = cdmDatabaseSchema,
                                 resultsDatabaseSchema = resultsDatabaseSchema,
                                 cdmSourceName = "test",
                                 numThreads = 1,
                                 sqlOnly = FALSE,
                                 outputFolder = "output",
                                 verboseMode = FALSE,
                                 writeToTable = FALSE,
                                 checkNames = "measurePersonCompleteness"
                                 )

      expect_true(nrow(results$CheckResults) > 0)
    }
  }
})
