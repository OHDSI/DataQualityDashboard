library(testthat)

test_that("Execute DQ checks", {
  
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
                                         extraSettings = sysExtraSettings)
    
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
    }
  }
})