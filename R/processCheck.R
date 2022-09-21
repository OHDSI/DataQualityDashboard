#' Internal function to send the fully qualified sql to the database and return the numerical result.
#' 
#' @param connection                A connection for connecting to the CDM database using the DatabaseConnector::connect(connectionDetails) function.
#' @param connectionDetails         A connectionDetails object for connecting to the CDM database.
#' @param check                     The data quality check
#' @param checkDescription          The description of the data quality check
#' @param sql                       The fully qualified sql for the data quality check
#' @param outputFolder              The folder to output logs and SQL files to.
#' 
#' @keywords internal
#'

.processCheck <- function(connection,
                          connectionDetails, 
                          check, 
                          checkDescription, 
                          sql, 
                          outputFolder) {
  singleThreaded <- TRUE
  start <- Sys.time()
  if (is.null(connection)) {
    singleThreaded <- FALSE
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    on.exit(DatabaseConnector::disconnect(connection = connection))  
  }
  
  errorReportFile <- file.path(outputFolder, "errors", 
                               sprintf("%s_%s_%s_%s.txt",
                                       checkDescription$checkLevel,
                                       checkDescription$checkName,
                                       check["cdmTableName"],
                                       check["cdmFieldName"]))  
  tryCatch(
    expr = {
      if (singleThreaded) {
        if (.needsAutoCommit(connectionDetails, connection)) {
          rJava::.jcall(connection@jConnection, "V", "setAutoCommit", TRUE)
        }  
      }
      
      result <- DatabaseConnector::querySql(connection = connection, sql = sql, 
                                            errorReportFile = errorReportFile)
      
      delta <- difftime(Sys.time(), start, units = "secs")
      .recordResult(result = result, check = check, checkDescription = checkDescription, sql = sql,  
                                            executionTime = sprintf("%f %s", delta, attr(delta, "units")))
    },
    warning = function(w) {
      ParallelLogger::logWarn(sprintf("[Level: %s] [Check: %s] [CDM Table: %s] [CDM Field: %s] %s", 
                                      checkDescription$checkLevel,
                                      checkDescription$checkName, 
                                      check["cdmTableName"], 
                                      check["cdmFieldName"], w$message))
      .recordResult(check = check, checkDescription = checkDescription, sql = sql, warning = w$message)
    },
    error = function(e) {
      ParallelLogger::logError(sprintf("[Level: %s] [Check: %s] [CDM Table: %s] [CDM Field: %s] %s", 
                                       checkDescription$checkLevel,
                                       checkDescription$checkName, 
                                       check["cdmTableName"], 
                                       check["cdmFieldName"], e$message))
      .recordResult(check = check, checkDescription = checkDescription, sql = sql, error = e$message)  
    }
  ) 
}
