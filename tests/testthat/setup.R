# Only use devtools::load_all() when running tests directly with devtools
# R CMD check loads the package automatically, so we don't need this
# Check if we're in an R CMD check environment by looking at the current directory
isRcmdCheck <- grepl("\\.Rcheck", getwd())

# Only run devtools setup in local development, not in CI/covr
isLocalDev <- !isRcmdCheck &&
  !identical(Sys.getenv("CI"), "true") &&
  !identical(Sys.getenv("COVR"), "true") &&
  requireNamespace("devtools", quietly = TRUE)

if (isLocalDev) {
  devtools::load_all()

  # Create symbolic link for sql directory if it doesn't exist
  # This allows testing with devtools::test
  packageRoot <- normalizePath(system.file("..", package = "DataQualityDashboard"))
  sqlLinkPath <- file.path(packageRoot, "sql")
  sqlPackagePath <- system.file("sql", package = "DataQualityDashboard")

  if (!file.exists(sqlLinkPath) && sqlPackagePath != "") {
    print("setting sql folder symbolic link")
    # Create symbolic link so code can be used in devtools::test()
    tryCatch(
      {
        if (requireNamespace("R.utils", quietly = TRUE)) {
          R.utils::createLink(link = sqlLinkPath, sqlPackagePath)
          options("use.devtools.sql_shim" = TRUE)
        } else {
          # Fallback: create a simple file.copy if R.utils is not available
          if (!dir.exists(sqlLinkPath)) {
            dir.create(sqlLinkPath, recursive = TRUE)
          }
          file.copy(from = sqlPackagePath, to = dirname(sqlLinkPath), recursive = TRUE, overwrite = TRUE)
          options("use.devtools.sql_shim" = TRUE)
        }
      },
      error = function(e) {
        warning("Failed to create symbolic link for SQL directory: ", e$message)
        # Continue without the symbolic link - the package should still work
      }
    )
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

if (Sys.getenv("DONT_DOWNLOAD_JDBC_DRIVERS", "") == "TRUE") {
  jdbcDriverFolder <- Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")
} else {
  jdbcDriverFolder <- tempfile("jdbcDrivers")
  dir.create(jdbcDriverFolder)
  DatabaseConnector::downloadJdbcDrivers("postgresql", jdbcDriverFolder)
  DatabaseConnector::downloadJdbcDrivers("sql server", jdbcDriverFolder)
  DatabaseConnector::downloadJdbcDrivers("oracle", jdbcDriverFolder)
  DatabaseConnector::downloadJdbcDrivers("redshift", jdbcDriverFolder)
}

connectionDetailsEunomia <- Eunomia::getEunomiaConnectionDetails()
cdmDatabaseSchemaEunomia <- "main"
resultsDatabaseSchemaEunomia <- "main"

# Separate connection details for NA tests, as this requires removing records
connectionDetailsEunomiaNaChecks <- Eunomia::getEunomiaConnectionDetails()

# Separate connection details for plausibleAfterBirth test
connectionDetailsPlausibleAfterBirth <- Eunomia::getEunomiaConnectionDetails()

# Separate connection details for observation period overlap test
connectionDetailsEunomiaOverlap <- Eunomia::getEunomiaConnectionDetails()
