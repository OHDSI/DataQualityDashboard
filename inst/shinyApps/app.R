library(shiny)
server <- function(input, output, session) {
  observe({
    results <- jsonlite::read_json(path = Sys.getenv("jsonPath"))
    session$sendCustomMessage("results", results)
  })
}

ui <- fluidPage(
  suppressDependencies("bootstrap"),
  shiny::htmlTemplate("www/index.html"),
  tags$head(
    tags$script(src = "js/loadResults.js"),
    tags$script("Shiny.addCustomMessageHandler('results', loadResults);")
  )
)

shiny::shinyApp(ui = ui, server = server)

