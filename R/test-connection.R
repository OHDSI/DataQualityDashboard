testConnection <- function(dataType, server, port, dataBaseSchema, user, password, httpPath) {
  Sys.setenv('DATABASECONNECTOR_JAR_FOLDER' = '~/jdbcDrivers')
  
  if(dataType == 'databricks') {
    connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "spark",                                                 connectionString
                                                 connectionString = sprintf("jdbc:spark://%s:%s/default;transportMode=http;ssl=1;httpPath=%s;AuthMech=3;UseNativeQuery=1;", server, port, httpPath),
                                                 user = "token",
                                                 password = password)
  }
  else {
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dataType,
                                                                  user = user,
                                                                  password = password,
                                                                  server = server,
                                                                  port = port,
                                                                  extraSettings = "")
  }
  print("Testing connection to CDM database...")
  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  DatabaseConnector::disconnect(connection)
  print("Test connection successfully completed")
}