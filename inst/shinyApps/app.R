library(shiny)
server <- function(input, output, session) {
  observe({
    jsonPath <- Sys.getenv("jsonPath")
    results <- DataQualityDashboard::convertJsonResultsFileCase(jsonPath, writeToFile = FALSE, targetCase = "camel")
    results <- jsonlite::parse_json(jsonlite::toJSON(results))
    session$sendCustomMessage("results", results)
  })
}

ui <- fluidPage(
  suppressDependencies("bootstrap"),
  shiny::htmlTemplate(filename = "www/index.html"),
  tags$head(
    tags$script(src = "js/loadResults.js"),
    tags$script("Shiny.addCustomMessageHandler('results', loadResults);")
  )
)

shiny::shinyApp(ui = ui, server = server)

