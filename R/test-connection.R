testConnection <- function(dataType, server, port, dataBaseSchema, user, password) {
  Sys.setenv('DATABASECONNECTOR_JAR_FOLDER' = '~/jdbcDrivers')
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dataType,
                                                                  user = user,
                                                                  password = password,
                                                                  server = server,
                                                                  port = port,
                                                                  extraSettings = "")
  print("Testing connection to CDM database...")
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  DatabaseConnector::disconnect(connection)
  print("Test connection successfully completed")
}