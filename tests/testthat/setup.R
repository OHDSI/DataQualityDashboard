# Only use devtools::load_all() when running tests directly with devtools
# R CMD check loads the package automatically, so we don't need this
# Check if we're in an R CMD check environment by looking at the current directory
isRcmdCheck <- grepl("\\.Rcheck", getwd())

# Check if we're running under covr
isCovr <- Sys.getenv("R_COVR") == "true" || 
          any(grepl("covr", sapply(sys.calls(), function(x) deparse(x)[1])))

# Skip problematic setup when running under covr
if (!isCovr) {
  if (!isRcmdCheck && requireNamespace("devtools", quietly = TRUE)) {
    devtools::load_all()
    
    # Create symbolic link for sql directory if it doesn't exist
    # This allows testing with devtools::test
    packageRoot <- normalizePath(system.file("..", package = "DataQualityDashboard"))
    sqlLinkPath <- file.path(packageRoot, "sql")
    sqlPackagePath <- system.file("sql", package = "DataQualityDashboard")
    
    if (!file.exists(sqlLinkPath) && sqlPackagePath != "") {
      print("setting sql folder symbolic link")
      # Create symbolic link so code can be used in devtools::test()
      tryCatch({
        R.utils::createLink(link = sqlLinkPath, sqlPackagePath)
        options("use.devtools.sql_shim" = TRUE)
      }, error = function(e) {
        warning("Failed to create symbolic link for SQL directory: ", e$message)
        # Continue without the symbolic link - the package should still work
      })
    }
  }

  # Set up JDBC drivers with error handling
  if (Sys.getenv("DONT_DOWNLOAD_JDBC_DRIVERS", "") == "TRUE") {
    jdbcDriverFolder <- Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")
  } else {
    jdbcDriverFolder <- tempfile("jdbcDrivers")
    dir.create(jdbcDriverFolder)
    
    # Download JDBC drivers with error handling
    tryCatch({
      DatabaseConnector::downloadJdbcDrivers("postgresql", jdbcDriverFolder)
      DatabaseConnector::downloadJdbcDrivers("sql server", jdbcDriverFolder)
      DatabaseConnector::downloadJdbcDrivers("oracle", jdbcDriverFolder)
      DatabaseConnector::downloadJdbcDrivers("redshift", jdbcDriverFolder)
    }, error = function(e) {
      warning("Failed to download JDBC drivers: ", e$message)
      # Continue without JDBC drivers - tests that don't need them should still work
    })
  }
}

# Ensure the package is properly loaded and SQL files are accessible
if (!requireNamespace("DataQualityDashboard", quietly = TRUE)) {
  # Try to load the package if it's not already loaded
  library(DataQualityDashboard)
}

# Verify SQL files are accessible
sqlFile <- system.file("sql", "sql_server", "field_plausible_after_birth.sql", package = "DataQualityDashboard")
if (sqlFile == "") {
  stop("Cannot find SQL files. Make sure the package is properly loaded.")
}

# Set up Eunomia connection details with error handling (only if not running under covr)
if (!isCovr) {
  tryCatch({
    connectionDetailsEunomia <- Eunomia::getEunomiaConnectionDetails()
    cdmDatabaseSchemaEunomia <- "main"
    resultsDatabaseSchemaEunomia <- "main"
    
    # Separate connection details for NA tests, as this requires removing records
    connectionDetailsEunomiaNaChecks <- Eunomia::getEunomiaConnectionDetails()
    
    # Separate connection details for plausibleAfterBirth test
    connectionDetailsPlausibleAfterBirth <- Eunomia::getEunomiaConnectionDetails()
  }, error = function(e) {
    stop("Failed to set up Eunomia connection details: ", e$message, 
         "\nMake sure the Eunomia package is properly installed and available.")
  })
}
