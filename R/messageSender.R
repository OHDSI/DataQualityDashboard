library(websocket)
library(properties)

createMessageSender <- function(userId) {
  result <- NULL

  if (is.null(userId) || all(userId == "")) {
    result <- createDefaultMessageSender()
  } else {
    result <- createWsMessageSender(userId)
  }

  return(result)
}

createDefaultMessageSender <- function() {
  connect <- function() { }

  send <- function(message) { }

  close <- function() { }

  result <- list(
    connect = connect,
    send = send,
    close = close
  )
}

createWsMessageSender <- function(userId) {
  props <- properties::read.properties('~/R/properties/default.properties')
  server <- props$host
  url <- paste(server, '/dqd/progress', collapse = '')

  ws <- WebSocket$new(url, autoConnect = FALSE)

  ws$onOpen(function(event) {
    cat("Connection opened\n")
  })
  ws$onClose(function(event) {
    cat("Client disconnected with code ", event$code,
        " and reason ", event$reason, "\n", sep = "")
  })
  ws$onError(function(event) {
    cat("Client failed to connect: ", event$message, "\n")
  })

  connect <- function() {
    ws$connect()
    pollUntilConnected(ws)
  }

  send <- function(message) {
    ws$send(
      parseMessage(message, userId)
    )
  }

  close <- function() {
    ws$close()
  }

  result <- list(
    ws = ws,
    connect = connect,
    send = send,
    close = close
  )

  return(result)
}

# Wait up to 3 seconds for websocket connection to be open.
pollUntilConnected <- function(ws, timeout = 3) {
  connected <- FALSE
  end <- Sys.time() + timeout
  while (!connected && Sys.time() < end) {
    # Need to run the event loop for websocket to complete connection.
    later::run_now(1)

    ready_state <- ws$readyState()
    if (ready_state == 0L) {
      # 0 means we're still trying to connect.
      # For debugging, indicate how many times we've done this.
      cat(".")
    } else if (ready_state == 1L) {
      connected <- TRUE
    } else {
      break
    }
  }

  if (!connected) {
    stop("Unable to establish websocket connection.")
  }
}

parseMessage <- function(message, userId) {
  parsedMessage <- sprintf("{ \"userId\": \"%s\", \"payload\": \"%s\" }", userId, message)
  return(parsedMessage)
}
