library("dplyr")

checkDescriptions <- read.csv("inst/csv/OMOP_CDMv5.3.1_Check_Descriptions.csv", stringsAsFactors = F)
fieldChecks <- read.csv("inst/csv/OMOP_CDMv5.3.1_Field_Level.csv", stringsAsFactors = F)

# populate with your details
# connectionDetails <-

connection <- DatabaseConnector::connect(connectionDetails)

cdmDatabaseSchema <- "cdm"
packageName <- "DataQualityDashboard"

checkId <- 0
checkCount <- 0
checkResults <- data.frame()

# TODO - make the code robust enough to handle all check levels
checkDescriptions <- checkDescriptions[checkDescriptions$CHECK_LEVEL=="FIELD" & checkDescriptions$EVALUATION_FILTER!="",]

recordResult <- function(result, checkId, checkDescription, sql) {
  result$CHECK_ID <- checkId
  result$QUERY_TEXT <- sql
  result$CATEGORY <- checkDescription$KAHN_CATEGORY
  checkResults <<- dplyr::bind_rows(checkResults,result)  
}

processCheck <- function(checkId, checkDescription, sql) {
  result <- DatabaseConnector::querySql(connection,sql)
  recordResult(result, checkId, checkDescription, sql)
}

for (i in 1:nrow(checkDescriptions)) {
  checkDescription <- checkDescriptions[i,]
 
  filterExpression <- paste0("fieldChecks %>% filter(", checkDescription$EVALUATION_FILTER, ")")
  checks <- eval(parse(text=filterExpression))
  
  if (nrow(checks) > 0) {
    for (c in 1:nrow(checks)) {
      checkId <- checkId + 1
      check <- checks[c,]
      sql <- SqlRender::loadRenderTranslateSql(
        dbms = connectionDetails$dbms,
        sqlFilename = checkDescription$SQL_FILE, 
        packageName = packageName,
        cdmTableName = check$CDM_TABLE,
        cdmFieldName = check$CDM_FIELD,
        fkTableName = check$FK_TABLE,
        fkFieldName = check$FK_FIELD,
        cdmDatabaseSchema = cdmDatabaseSchema,
        warnOnMissingParameters = FALSE
      )
  
      # need to capture the result status
      tryCatch(
        expr = processCheck(checkId = checkId, checkDescription = checkDescription, sql = sql),
        warning = function(w) {
          result <- list(WARNING = w$message)
          recordResult(result, checkId, checkDescription, sql)
        },
        error = function(e) {
          result <- list(ERROR = e$message)
          recordResult(result, checkId, checkDescription, sql)  
          # redshift specific fix 
          DatabaseConnector::executeSql(connection, "ROLLBACK;")
        }
      )
    }
  } else {
    writeLines(paste0("Warning: Evaluation resulted in no checks: ", filterExpression))
  }
}

metadata <- list(CDMName = "CDM Name", CDMVersion = "CDM Version", ETLDetails="ETL used to convert native to CDM", VocabularyVersion = "Vocabulary 2019.1")
overview <- list(
  total = nrow(checkResults), 
  passed = nrow(checkResults[checkResults$NUM_VIOLATED_ROWS==0,]), 
  passedPercent = round(nrow(checkResults[checkResults$NUM_VIOLATED_ROWS==0,])/nrow(checkResults) * 100)
)
result <- list(CheckResults = checkResults, Metadata = cdmDatabaseSchema, Overview = overview)
resultJson <- RJSONIO::toJSON(result)
write(resultJson,file.path(getwd(), "inst", "results.json"))



