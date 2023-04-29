if (Sys.getenv("DONT_DOWNLOAD_JDBC_DRIVERS", "") == "TRUE") {
  jdbcDriverFolder <- Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")
} else {
  jdbcDriverFolder <- tempfile("jdbcDrivers")
  dir.create(jdbcDriverFolder)
  downloadJdbcDrivers("postgresql", jdbcDriverFolder)
  downloadJdbcDrivers("sql server", jdbcDriverFolder)
  downloadJdbcDrivers("oracle", jdbcDriverFolder)
}

connectionDetailsEunomia <- Eunomia::getEunomiaConnectionDetails()
cdmDatabaseSchemaEunomia <- "main"
resultsDatabaseSchemaEunomia <- "main"

# dbms <- getOption("dbms", default = "sqlite")
# if (dbms == "sqlite") {
# connectionDetails <- Eunomia::getEunomiaConnectionDetails()
# cdmDatabaseSchema <- "main"
# resultsDatabaseSchema <- "main"
# cdmVersion <- 5
# }
# if (dbms == "postgresql") {
#   DatabaseConnector::downloadJdbcDrivers("postgresql", pathToDriver = jdbcDriverFolder)
#   connectionDetails <- createConnectionDetails(dbms = "postgresql",
#                                                user = Sys.getenv("CDM5_POSTGRESQL_USER"),
#                                                password = URLdecode(Sys.getenv("CDM5_POSTGRESQL_PASSWORD")),
#                                                server = Sys.getenv("CDM5_POSTGRESQL_SERVER"),
#                                                pathToDriver = jdbcDriverFolder)
#
#   cdmDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
#   cdmVersion <- 5
# }
# if (dbms == "sql server") {
#   DatabaseConnector::downloadJdbcDrivers("sql server", pathToDriver = jdbcDriverFolder)
#   connectionDetails <- createConnectionDetails(dbms = "sql server",
#                                                user = Sys.getenv("CDM5_SQL_SERVER_USER"),
#                                                password = URLdecode(Sys.getenv("CDM5_SQL_SERVER_PASSWORD")),
#                                                server = Sys.getenv("CDM5_SQL_SERVER_SERVER"),
#                                                pathToDriver = jdbcDriverFolder)
#   cdmDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
#   cdmVersion <- 5
# }
# if (dbms == "oracle") {
#   DatabaseConnector::downloadJdbcDrivers("oracle", pathToDriver = jdbcDriverFolder)
#   connectionDetails <- createConnectionDetails(dbms = "oracle",
#                                                user = Sys.getenv("CDM5_ORACLE_USER"),
#                                                password = URLdecode(Sys.getenv("CDM5_ORACLE_PASSWORD")),
#                                                server = Sys.getenv("CDM5_ORACLE_SERVER"),
#                                                pathToDriver = jdbcDriverFolder)
#   cdmDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
#
#   # Restore temp schema setting after tests complete
#   oldTempSchema <- getOption("sqlRenderTempEmulationSchema")
#   options("sqlRenderTempEmulationSchema" = Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA"))
#   cdmVersion <- 5
# }
