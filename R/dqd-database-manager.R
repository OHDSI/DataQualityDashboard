library(DatabaseConnector)
library(SqlRender)
library(properties)

#' DQD DatabaseManager
#'
#' @param scanId - primary key of data_quality_scans table
#' @return return DQD databaseManager if scan id not null
createDqdDatabaseManager <- function(scanId) {
  result <- NULL
  if (is.null(scanId)) {
    result <- createFakeDqdDatabaseManager()
    print("Created Fake Database Manager!")
  } else {
    result <- createRealDqdDatabaseManager(scanId)
    print("Created DQD Database Manager!")
  }

  return(result)
}

#' DatabaseManager for development
#' Not implemented
createFakeDqdDatabaseManager <- function() {
  message <- "Fake DQD Database Manager not implemented"
  print(message)
  stop(message)
}

#' DQD database manager
#'
#' @param scanId - primary key of data_quality_scans table
#' @export
#' @return list of dbLogger and interruptor
#' dbLogger - log progress messages to database
#' interruptor - check is data_quality_scans status code ABORT
createRealDqdDatabaseManager <- function(scanId) {
  props <- properties::read.properties('~/R/properties/default.properties')
  dataType <- props$dbms
  server <- paste0(props$server, "/", props$database)
  port <- props$port
  schema <- props$schema
  dbUsername <- props$user
  password <- props$password

  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dataType,
                                                                  user = dbUsername,
                                                                  password = password,
                                                                  server = server,
                                                                  port = port,
                                                                  extraSettings = "")

  createLogger <- function() {
    MAX_MESSAGE_LENGTH <- 1000
    STEPS_COUNT <- 22
    completedStepsCount <- 0

    INFO_STATUS <- list(code = 1, name = "INFO")
    DEBBUG_STATUS <- list(code = 2, name = "DEBUG")
    WARNING_STATUS <- list(code = 3, name = "WARNING")
    ERROR_STATUS <- list(code = 4, name = "ERROR")

    incrementCompletedStepsCount <- function() {
      completedStepsCount <<- completedStepsCount + 1
    }

    log <- function(message, status) {
      print(paste0("Log message: ", message))
      percent <- completedStepsCount * 100 / STEPS_COUNT
      time <- Sys.time()
      print("Connectiong to DQD database...")
      if (nchar(message) > 1000) {
        message <- substr(message, 0, MAX_MESSAGE_LENGTH)
      }
      data <- data.frame(
        MESSAGE = message,
        PERCENT = percent,
        STATUS_CODE = status$code,
        STATUS_NAME = status$name,
        TIME = time,
        SCAN_ID = scanId
      )
      connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
      DatabaseConnector::insertTable(
        connection = connection,
        databaseSchema = schema,
        tableName = 'data_quality_logs',
        data = data,
        createTable = FALSE,
        dropTableIfExists = FALSE
      )
      DatabaseConnector::disconnect(connection)
      print("Log message successfully saved to DQD database!")
    }

    info <- function(message) {
      log(message, INFO_STATUS)
    }

    debug <- function(message) {
      log(message, DEBBUG_STATUS)
    }

    warning <- function(message) {
      log(message, WARNING_STATUS)
    }

    error <- function(message) {
      log(message, ERROR_STATUS)
    }

    result <- list(
      incrementCompletedStepsCount = incrementCompletedStepsCount,
      info = info,
      debug = debug,
      warning = warning,
      error = error
    )

    return(result)
  }

  createInterruptor <- function() {
    ABORT_STATUS_CODE <- 3
    ABORT_STATUS_NAME <- "ABORTED"

    isAborted <- function() {
      print("Connectiong to DQD database...")
      connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
      print("Selectiong scan process status")
      sql <- SqlRender::render(sql = "select status_code, status_name
                                      from @schema.data_quality_scans
                                      where id = @scanId;",
                               schema = schema,
                               scanId = scanId)
      sql <- SqlRender::translate(sql = sql, targetDialect = connectionDetails$dbms)
      result <- DatabaseConnector::querySql(connection = connection, sql = sql)
      currentStatusCode <- result$STATUS_CODE
      currentStatusName <- result$STATUS_NAME
      DatabaseConnector::disconnect(connection)
      result <- currentStatusCode == ABORT_STATUS_CODE
      print(paste0("Current scan process status name: ", currentStatusName))

      return(result)
    }

    result <- list(
      isAborted = isAborted
    )

    return(result)
  }

  result <- list(
    logger = createLogger(),
    interruptor = createInterruptor()
  )

  return(result)
}