library(DatabaseConnector)

Sys.setenv('DATABASECONNECTOR_JAR_FOLDER' = '~/jdbcDrivers')

DatabaseConnector::downloadJdbcDrivers('sql server')
DatabaseConnector::downloadJdbcDrivers('postgresql')
DatabaseConnector::downloadJdbcDrivers('oracle')
DatabaseConnector::downloadJdbcDrivers('redshift')
DatabaseConnector::downloadJdbcDrivers('spark')