library(shiny)
server <- function(input, output, session) {
  observe({
    jsonPath <- Sys.getenv("jsonPath")
    results <- DataQualityDashboard::convertJsonResultsFileCase(jsonPath, writeToFile = FALSE, targetCase = "camel")
    
    # Add severity for each check if missing
    if (!('severity' %in% names(results$CheckResults))) {
      tryCatch({
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
            checkDescriptionsDf |> dplyr::select(checkLevel, checkName, severity),
            dplyr::join_by('checkLevel', 'checkName')
          )
      }, error = function(e) {
        results$CheckResults$severity <- NA
      })
    }
    
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

