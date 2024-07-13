if (Sys.getenv("DONT_DOWNLOAD_JDBC_DRIVERS", "") == "TRUE") {
  jdbcDriverFolder <- Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")
} else {
  jdbcDriverFolder <- tempfile("jdbcDrivers")
  dir.create(jdbcDriverFolder)
  downloadJdbcDrivers("postgresql", jdbcDriverFolder)
  downloadJdbcDrivers("sql server", jdbcDriverFolder)
  downloadJdbcDrivers("oracle", jdbcDriverFolder)
  downloadJdbcDrivers("redshift", jdbcDriverFolder)
}

connectionDetailsEunomia <- Eunomia::getEunomiaConnectionDetails()
cdmDatabaseSchemaEunomia <- "main"
resultsDatabaseSchemaEunomia <- "main"

# Separate connection details for NA tests, as this requires removing records
connectionDetailsEunomiaNaChecks <- Eunomia::getEunomiaConnectionDetails()
