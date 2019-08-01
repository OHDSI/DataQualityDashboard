checkDescriptions <- read.csv("inst/csv/OMOP_CDMv5.3.1_Check_Descriptions.csv")
fieldChecks <- read.csv("inst/csv/OMOP_CDMv5.3.1_Field_Level.csv", stringsAsFactors = FALSE)

# populate with your details
connectionDetails <- DatabaseConnector::createConnectionDetails()

connection <- DatabaseConnector::connect(connectionDetails)
cdmDatabaseSchema <- "cdm"
packageName <- "DataQualityDashboard"

# focus - TOTAL # of Checks and how many you passed.
# break down by category afterwards
fkChecks <- fieldChecks[fieldChecks$IS_FOREIGN_KEY=="Yes",]

checkId <- 0
checkCount <- 0
checkPassCount <- 0
checkFailCount <- 0

results <- data.frame()
for (i in 1:nrow(fkChecks)) {
  checkId <- checkId + 1
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
  
  # need to capture the result status
  result <- DatabaseConnector::querySql(connection,sql)
  result$CHECK_ID <- checkId
  result$QUERY_TEXT <- sql
  results <- rbind(results,result)
}

integerChecks <- fieldChecks[fieldChecks$CDM_DATATYPE=="integer",]
sqlFileName <- "field_cdm_datatype.sql"
for (i in 1:nrow(integerChecks)) {
  checkId <- checkId + 1
  sql <- SqlRender::loadRenderTranslateSql(
    dbms = connectionDetails$dbms,
    sqlFilename = sqlFileName, 
    packageName = packageName,
    cdmTableName = integerChecks[i,]$CDM_TABLE,
    cdmFieldName = integerChecks[i,]$CDM_FIELD,
    cdmDatabaseSchema = cdmDatabaseSchema
  )
  
  result <- DatabaseConnector::querySql(connection,sql)
  result$CHECK_ID <- checkId
  result$QUERY_TEXT <- sql
  results <- rbind(results,result)
}

requiredChecks <- fieldChecks[fieldChecks$IS_REQUIRED=="Yes",]
sqlFileName <- "field_is_not_nullable.sql"
for (i in 1:nrow(requiredChecks)) {
  checkId <- checkId + 1
  sql <- SqlRender::loadRenderTranslateSql(
    dbms = connectionDetails$dbms,
    sqlFilename = sqlFileName, 
    packageName = packageName,
    cdmTableName = requiredChecks[i,]$CDM_TABLE,
    cdmFieldName = requiredChecks[i,]$CDM_FIELD,
    cdmDatabaseSchema = cdmDatabaseSchema
  )
  result <- DatabaseConnector::querySql(connection,sql)
  result$CHECK_ID <- checkId
  result$QUERY_TEXT <- sql
  results <- rbind(results,result)
}

classChecks <- fieldChecks[fieldChecks$FK_CLASS!="",]
sqlFileName <- "field_fk_class.sql"
for (i in 1:nrow(classChecks)) {
  checkId <- checkId + 1
  sql <- SqlRender::loadRenderTranslateSql(
    dbms = connectionDetails$dbms,
    sqlFilename = sqlFileName, 
    packageName = packageName,
    cdmTableName = classChecks[i,]$CDM_TABLE,
    cdmFieldName = classChecks[i,]$CDM_FIELD,
    fkTableName = classChecks[i,]$FK_TABLE,
    fkFieldName = classChecks[i,]$FK_FIELD,
    fkDomain = classChecks[i,]$FK_DOMAIN,
    fkClass = classChecks[i,]$FK_CLASS,
    cdmDatabaseSchema = cdmDatabaseSchema
  )
  result <- DatabaseConnector::querySql(connection,sql)
  result$CHECK_ID <- checkId
  result$QUERY_TEXT <- sql
  results <- rbind(results,result)
}
