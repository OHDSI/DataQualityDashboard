library(shiny)
server <- function(input, output, session) {
  observe({
    jsonPath <- Sys.getenv("jsonPath")
    results <- DataQualityDashboard::convertJsonResultsFileCase(jsonPath, writeToFile = FALSE, targetCase = "camel")
    
    tryCatch({
      # Read checkDescription to get severity status for each check
      cdmVersion <- results$Metadata$cdmVersion
      checkDescriptionsDf <- readr::read_csv(
        file = system.file(
          "csv",
          sprintf("OMOP_CDMv%s_Check_Descriptions.csv", substr(sub('$v', '', cdmVersion), 1, 3)),  
          package = "DataQualityDashboard"
        ),
        show_col_types = FALSE
      )

      results$CheckResults <- results$CheckResults |>
        dplyr::left_join(
          dplyr::select(checkDescriptionsDf, checkName, severity),
          dplyr::join_by('checkName')
        )
    }, error = function(e) {
      results$CheckResults$severity <- NA
    })
    
    results$appVersion <- as.character(packageVersion('DataQualityDashboard'))
    
    # Fix json formatting
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

