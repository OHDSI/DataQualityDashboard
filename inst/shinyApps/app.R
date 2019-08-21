library(shiny)
server <- function(input, output, session) {
  observe({
    results <- jsonlite::read_json(path = Sys.getenv("jsonPath"))
    session$sendCustomMessage("results", results)
  })
}

ui <- fluidPage(
<<<<<<< HEAD
  suppressDependencies("bootstrap"),
  shiny::htmlTemplate("www/index.html"),
=======
  shiny::htmlTemplate(filename = "www/index.html"),
>>>>>>> 8879eb1de03cdfcfe71bdd91df7a097b56e2750b
  tags$head(
    tags$script(src = "js/loadResults.js"),
    tags$script("Shiny.addCustomMessageHandler('results', loadResults);")
  )
)

<<<<<<< HEAD
shiny::shinyApp(ui = ui, server = server)
=======
shiny::shinyApp(ui = ui, 
                server = server)
>>>>>>> 8879eb1de03cdfcfe71bdd91df7a097b56e2750b

