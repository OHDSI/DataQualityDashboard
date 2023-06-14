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

remove_sql_comments <- function(sql) {
  sql0 <- gsub("--.*?\\n|--.*?\\r", " ", sql) # remove single-line SQL comments
  sql1 <- gsub("\\r|\\n|\\t", " ", sql0) # convert tabs and newlines to spaces
  sql2 <- gsub("/*", "@@@@ ", sql1, fixed = TRUE) # must add spaces between multi-line comments for quote removal to work
  sql3 <- gsub("*/", " @@@@", sql2, fixed = TRUE) # must add spaces between multi-line comments for quote removal to work
  sql4 <- gsub("@@@@ .+? @@@@", " ", sql3, ) # remove multi-line comments
  sql5 <- gsub("\\s+", " ", sql4) # remove multiple spaces
}
