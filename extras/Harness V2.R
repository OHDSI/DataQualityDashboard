library("dplyr")

packageName <- "DataQualityDashboard"
checkDescriptions <- read.csv("inst/csv/OMOP_CDMv5.3.1_Check_Descriptions.csv", stringsAsFactors = F)
fieldChecks <- read.csv("inst/csv/OMOP_CDMv5.3.1_Field_Level.csv", stringsAsFactors = F)

# populate with your details
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms     = Sys.getenv("dbms"),
  user     = Sys.getenv("user"),
  password = Sys.getenv("password"),
  server   = Sys.getenv("server"),
  port     = Sys.getenv("port")  
)

connection <- DatabaseConnector::connect(connectionDetails)
cdmDatabaseSchema <- "cdm"


checkId <- 0
checkCount <- 0
checkResults <- data.frame()

# TODO - make the code robust enough to handle all check levels
checkDescriptions <- checkDescriptions[checkDescriptions$CHECK_LEVEL=="FIELD" & checkDescriptions$EVALUATION_FILTER!="",]

recordResult <- function(result, checkId, check, checkDescription, sql) {
  result$CHECK_ID <- checkId
  result$QUERY_TEXT <- sql
  result$CHECK_NAME <- checkDescription$CHECK_NAME
  result$CHECK_LEVEL <- checkDescription$CHECK_LEVEL
  result$CHECK_DESCRIPTION <- checkDescription$CHECK_DESCRIPTION
  result$CDM_TABLE <- check$CDM_TABLE
  result$CDM_FIELD <- check$CDM_FIELD
  result$CATEGORY <- checkDescription$KAHN_CATEGORY
  result$SUBCATEGORY <- checkDescription$KAHN_SUBCATEGORY
  result$CONTEXT <- checkDescription$KAHN_CONTEXT
  checkResults <<- dplyr::bind_rows(checkResults,result)  
}

processCheck <- function(checkId, check, checkDescription, sql) {
  result <- DatabaseConnector::querySql(connection,sql)
  recordResult(result, checkId, check, checkDescription, sql)
}

for (i in 1:nrow(checkDescriptions)) {
  checkDescription <- checkDescriptions[i,]
  writeLines(paste("Processing check description", i, "of", nrow(checkDescriptions)))
 
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
        expr = processCheck(checkId = checkId, check = check, checkDescription = checkDescription, sql = sql),
        warning = function(w) {
          result <- list(WARNING = w$message)
          recordResult(result, checkId, check, checkDescription, sql)
        },
        error = function(e) {
          result <- list(ERROR = e$message)
          recordResult(result, checkId, check, checkDescription, sql)  
          # redshift specific fix 
          DatabaseConnector::executeSql(connection, "ROLLBACK;")
        }
      )
    }
  } else {
    writeLines(paste0("Warning: Evaluation resulted in no checks: ", filterExpression))
  }
}

# capture metadata
cdmSourceData <- DatabaseConnector::querySql(connection, "select * from cdm_source")

# prepare output
metadata <- cdmSourceData

countTotal <- nrow(checkResults)
countFailed <- nrow(checkResults[(!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS > 0) | !is.na(checkResults$ERROR),])

# set a flag for when the check has failed
checkResults[,"FAILED"] <- 0
checkResults[(!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS > 0) | !is.na(checkResults$ERROR),"FAILED"]<- 1

countThresholdFailure <- nrow(checkResults[(!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS>0),])
countErrorFailure <- nrow(checkResults[!is.na(checkResults$ERROR),])
countPassed <- countTotal - countFailed

countTotalPlausibility = nrow(checkResults[checkResults$CATEGORY=='Plausibility',])
countTotalConformance = nrow(checkResults[checkResults$CATEGORY=='Conformance',])
countTotalCompleteness = nrow(checkResults[checkResults$CATEGORY=='Completeness',])
countFailedPlausibility = nrow(checkResults[checkResults$CATEGORY=='Plausibility' & (!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS > 0 | !is.na(checkResults$ERROR)),])
countFailedConformance = nrow(checkResults[checkResults$CATEGORY=='Conformance' & (!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS > 0 | !is.na(checkResults$ERROR)),])
countFailedCompleteness = nrow(checkResults[checkResults$CATEGORY=='Completeness' & (!is.na(checkResults$NUM_VIOLATED_ROWS) & checkResults$NUM_VIOLATED_ROWS > 0 | !is.na(checkResults$ERROR)),])
countPassedPlausibility = countTotalPlausibility - countFailedPlausibility
countPassedConformance = countTotalConformance - countFailedConformance
countPassedCompleteness = countTotalCompleteness - countFailedCompleteness

overview <- list(
  countTotal = countTotal, 
  countPassed = countPassed, 
  countFailed = countFailed,
  percentPassed = round(countPassed / countTotal * 100),
  percentFailed = round(countFailed / countTotal * 100),
  countTotalPlausibility = countTotalPlausibility,
  countTotalConformance = countTotalConformance,
  countTotalCompleteness = countTotalCompleteness,
  countFailedPlausibility = countFailedPlausibility,
  countFailedConformance = countFailedConformance,
  countFailedCompleteness = countFailedCompleteness,
  countPassedPlausibility = countPassedPlausibility,
  countPassedConformance = countPassedConformance,
  countPassedCompleteness = countPassedCompleteness
)

result <- list(CheckResults = checkResults, Metadata = metadata, Overview = overview)
resultJson <-jsonlite::toJSON(result)

# TODO - add timestamp to result file output?
write(resultJson,file.path(getwd(), "inst", "results.json"))

# TODO - Write out data frame to table

# dqDashPOC(data = result)
