#' Custom ParallelLogger Appender Implementation see https://github.com/OHDSI/ParallelLogger/blob/main/R/Appenders.R
#'
#' @param dbLogger - DQD database logger see ./dqd-database-manager.R
#' @param ParallelLogger layout
#'
#' @export
createDqdLogAppender <- function(dbLogger, layout = ParallelLogger::layoutSimple) {
  appendFunction <- function (this, level, message, echoToConsole) {
    # Avoid note in check:
    missing(this)
    if (echoToConsole) {
      prefix <- '#DQD '
      if (startsWith(message, '#DQD ')) {
        msg <- substr(message, nchar(prefix), nchar(message))
        if (level == "INFO") {
          dbLogger$info(msg)
          dbLogger$incrementCompletedStepsCount()
        } else if (level == "DEBUG") {
          dbLogger$debug(msg)
        } else if (level == "WARN") {
          dbLogger$warning(msg)
        } else if (level == "ERROR" || level == "FATAL") {
          dbLogger$error(msg)
        }
      }
      writeLines(message, con = stdout())
    }
  }

  appender <- list(appendFunction = appendFunction, layout = layout)
  class(appender) <- "Appender"
  return(appender)
}