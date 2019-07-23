fieldChecks <- read.csv("inst/csv/OMOP_CDMv5.3.1_Field_Level.csv", stringsAsFactors = FALSE)

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql", 
  connectionString = "jdbc:postgresql://localhost:5432/DATABASE", 
  user="USER", 
  password = "PASSWORD")

connection <- DatabaseConnector::connect(connectionDetails)
cdmDatabaseSchema <- "public"
packageName <- "DataQualityDashboard"

fkChecks <- fieldChecks[fieldChecks$IS_FOREIGN_KEY=="Yes",]
for (i in 1:nrow(fkChecks)) {
  sql <- SqlRender::loadRenderTranslateSql(
    dbms = connectionDetails$dbms,
    sqlFilename = "is_foreign_key.sql", 
    packageName = packageName,
    cdmTableName = fkChecks[i,]$CDM_TABLE,
    cdmFieldName = fkChecks[i,]$CDM_FIELD,
    fkTableName = fkChecks[i,]$FK_TABLE,
    fkFieldName = fkChecks[i,]$FK_FIELD,
    cdmDatabaseSchema = cdmDatabaseSchema
  )
  
  DatabaseConnector::querySql(connection,sql)
}

integerChecks <- fieldChecks[fieldChecks$CDM_DATATYPE=="integer",]
for (i in 1:nrow(integerChecks)) {
  sql <- SqlRender::loadRenderTranslateSql(
    dbms = connectionDetails$dbms,
    sqlFilename = "field_cdm_datatype.sql", 
    packageName = packageName,
    cdmTableName = integerChecks[i,]$CDM_TABLE,
    cdmFieldName = integerChecks[i,]$CDM_FIELD,
    cdmDatabaseSchema = cdmDatabaseSchema
  )
  
  DatabaseConnector::querySql(connection,sql)
}

requiredChecks <- fieldChecks[fieldChecks$IS_REQUIRED=="Yes",]
for (i in 1:nrow(requiredChecks)) {
  sql <- SqlRender::loadRenderTranslateSql(
    dbms = connectionDetails$dbms,
    sqlFilename = "field_is_not_nullable.sql", 
    packageName = packageName,
    cdmTableName = requiredChecks[i,]$CDM_TABLE,
    cdmFieldName = requiredChecks[i,]$CDM_FIELD,
    cdmDatabaseSchema = cdmDatabaseSchema
  )
  DatabaseConnector::querySql(connection,sql)
}

classChecks <- fieldChecks[fieldChecks$FK_CLASS!="",]
for (i in 1:nrow(classChecks)) {
  sql <- SqlRender::loadRenderTranslateSql(
    dbms = connectionDetails$dbms,
    sqlFilename = "field_fk_class.sql", 
    packageName = packageName,
    cdmTableName = classChecks[i,]$CDM_TABLE,
    cdmFieldName = classChecks[i,]$CDM_FIELD,
    fkTableName = classChecks[i,]$FK_TABLE,
    fkFieldName = classChecks[i,]$FK_FIELD,
    fkDomain = classChecks[i,]$FK_DOMAIN,
    fkClass = classChecks[i,]$FK_CLASS,
    cdmDatabaseSchema = cdmDatabaseSchema
  )
  DatabaseConnector::querySql(connection,sql)
}
