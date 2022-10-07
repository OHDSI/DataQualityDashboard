#' Internal function to put the results of each quality check into a dataframe.
#' 
#' @param result                    The result of the data quality check
#' @param check                     The data quality check
#' @param checkDescription          The description of the data quality check
#' @param sql                       The fully qualified sql for the data quality check
#' @param executionTime             The total time it took to execute the data quality check
#' @param warning                   Any warnings returned from the server
#' @param error                     Any errors returned from the server
#' 
#' @keywords internal
#' @importFrom stats setNames
#' 


.recordResult <- function(result = NULL, 
                          check, 
                          checkDescription, 
                          sql, 
                          executionTime = NA,
                          warning = NA, 
                          error = NA) {
  
  columns <- lapply(names(check), function(c) {
    setNames(check[c], c)
  })
  
  params <- c(list(sql = checkDescription$checkDescription),
              list(warnOnMissingParameters = FALSE),
              lapply(unlist(columns, recursive = FALSE), toupper))
  
  reportResult <- data.frame(
    NUM_VIOLATED_ROWS = NA,
    PCT_VIOLATED_ROWS = NA,
    NUM_DENOMINATOR_ROWS = NA,
    EXECUTION_TIME = executionTime,
    QUERY_TEXT = sql,
    CHECK_NAME = checkDescription$checkName,
    CHECK_LEVEL = checkDescription$checkLevel,
    CHECK_DESCRIPTION = do.call(SqlRender::render, params),
    CDM_TABLE_NAME = check["cdmTableName"],
    CDM_FIELD_NAME = check["cdmFieldName"],
    CONCEPT_ID = check["conceptId"],
    UNIT_CONCEPT_ID = check["unitConceptId"],
    SQL_FILE = checkDescription$sqlFile,
    CATEGORY = checkDescription$kahnCategory,
    SUBCATEGORY = checkDescription$kahnSubcategory,
    CONTEXT = checkDescription$kahnContext,
    WARNING = warning,
    ERROR = error,
    checkId = .getCheckId(checkDescription$checkLevel, checkDescription$checkName, check["cdmTableName"], check["cdmFieldName"], check["conceptId"], check["unitConceptId"]),
    row.names = NULL, stringsAsFactors = FALSE
  )
  
  if (!is.null(result)) {
    reportResult$NUM_VIOLATED_ROWS <- result$NUM_VIOLATED_ROWS
    reportResult$PCT_VIOLATED_ROWS <- result$PCT_VIOLATED_ROWS
    reportResult$NUM_DENOMINATOR_ROWS <- result$NUM_DENOMINATOR_ROWS
  }
  reportResult
}
