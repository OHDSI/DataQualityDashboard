library(shiny)
library(reactable)
library(htmlwidgets)
library(htmltools)
library(formattable)
library(shinyWidgets)
# library(shinythemes)
library(dplyr)
source("load_data_10.R")

server <- function(input, output) {
  ################################################
  #### Panel: Overview                        ####
  ################################################
  if (checkString(dataT, "Validation")) {
    output$summary_dt1 <- renderUI({
      reactable(
        data1,
        striped = TRUE,
        highlight = TRUE,
        bordered = TRUE,
        theme = reactableTheme(
          borderColor = "#dfe2e5",
          # stripedColor = "#ecf0f1",
          highlightColor = "#f0f5f9",
          cellPadding = "8px 12px",
        ),
        rowStyle = function(index) {
          if (index == 4)
            list(fontWeight = "bold")
        },
        columns = list(
          CATEGORY = colDef(name = "Category", minWidth = 80),
          Validation.Pass = colDef(
            name = "Pass",
            minWidth = 60,
            align = "center"
          ),
          Verification.Pass = colDef(
            name = "Pass",
            minWidth = 60,
            align = "center"
          ),
          Total.Pass = colDef(
            name = "Pass",
            minWidth = 60,
            align = "center"
          ),
          Validation.Fail = colDef(
            name = "Fail",
            minWidth = 60,
            align = "center",
            style = list(color = "red")
          ),
          Verification.Fail = colDef(
            name = "Fail",
            minWidth = 60,
            align = "center",
            style = list(color = "red")
          ),
          Total.Fail = colDef(
            name = "Fail",
            minWidth = 60,
            align = "center",
            style = list(color = "red")
          ),
          Validation.Not_Applicable = colDef(
            name = "Not Applicable",
            minWidth = 60,
            align = "center"
          ),
          Verification.Not_Applicable = colDef(
            name = "Not Applicable",
            minWidth = 60,
            align = "center"
          ),
          Total.Not_Applicable = colDef(
            name = "Not Applicable",
            minWidth = 60,
            align = "center"
          ),
          Validation.Error = colDef(
            name = "Error",
            minWidth = 60,
            align = "center"
          ),
          Verification.Error = colDef(
            name = "Error",
            minWidth = 60,
            align = "center"
          ),
          Total.Error = colDef(
            name = "Error",
            minWidth = 60,
            align = "center"
          ),
          Validation.PctPass = colDef(
            name = "% Pass",
            minWidth = 60,
            align = "center",
            format =
              colFormat(separators = TRUE, digits = 0)
          ),
          Verification.PctPass = colDef(
            name = "% Pass",
            minWidth = 60,
            align = "center",
            format =
              colFormat(separators = TRUE, digits = 0)
          ),
          Total.PctPass = colDef(
            name = "% Pass",
            minWidth = 60,
            align = "center",
            format =
              colFormat(separators = TRUE, digits = 0)
          )
        ),
        columnGroups = list(
          colGroup(
            name = "Validation",
            columns = c(
              "Validation.Pass",
              "Validation.Fail",
              "Validation.Not_Applicable",
              "Validation.Error",
              "Validation.PctPass"
            )
          ),
          colGroup(
            name = "Verification",
            columns = c(
              "Verification.Pass",
              "Verification.Fail",
              "Verification.Not_Applicable",
              "Verification.Error",
              "Verification.PctPass"
            )
          ),
          colGroup(
            name = "Total",
            columns = c(
              "Total.Pass",
              "Total.Fail",
              "Total.Not_Applicable",
              "Total.Error",
              "Total.PctPass"
            )
          )
        )
      )
    })
  } else{
    output$summary_dt1 <- renderUI({
      reactable(
        data1,
        striped = TRUE,
        highlight = TRUE,
        bordered = TRUE,
        theme = reactableTheme(
          borderColor = "#dfe2e5",
          # stripedColor = "#ecf0f1",
          highlightColor = "#f0f5f9",
          cellPadding = "8px 12px",
        ),
        rowStyle = function(index) {
          if (index == 4)
            list(fontWeight = "bold")
        },
        columns = list(
          CATEGORY = colDef(name = "Category", minWidth = 80),
          Verification.Pass = colDef(
            name = "Pass",
            minWidth = 60,
            align = "center"
          ),
          Verification.Fail = colDef(
            name = "Fail",
            minWidth = 60,
            align = "center",
            style = list(color = "red")
          ),
          Verification.Not_Applicable = colDef(
            name = "Not Applicable",
            minWidth = 60,
            align = "center"
          ),
          Verification.Error = colDef(
            name = "Error",
            minWidth = 60,
            align = "center"
          ),
          Verification.PctPass = colDef(
            name = "% Pass",
            minWidth = 60,
            align = "center",
            format =
              colFormat(separators = TRUE, digits = 0)
          )
        ),
        columnGroups = list(
          colGroup(
            name = "Verification",
            columns = c(
              "Verification.Pass",
              "Verification.Fail",
              "Verification.Not_Applicable",
              "Verification.Error",
              "Verification.PctPass"
            )
          )
        )
      )
    })
  }
  
  
  ################################################
  #### Panel: Results                         ####
  ################################################
  
  output$summary_dt2 <- renderUI({
    filteredTable <- filter(data2, CATEGORY %in% input$cat) %>%
      filter(SUBCATEGORY %in% input$subcat) %>%
      filter(CONTEXT %in% input$cont) %>%
      filter(CHECK_NAME %in% input$check_na) %>%
      filter(CHECK_LEVEL %in% input$check_le) %>%
      filter(CHECK_STATUS %in% input$check_st)
    
    reactable(
      filteredTable,
      groupBy = c("CDM_TABLE_NAME", "CHECK_NAME", "CHECK_LEVEL"),
      defaultSorted = list(
        CDM_TABLE_NAME = "asc",
        CDM_TABLE_NAME = "asc",
        CDM_TABLE_NAME = "asc"
      ),
      defaultColDef = colDef(footerStyle = list(fontWeight = "bold")),
      striped = TRUE,
      highlight = TRUE,
      theme = reactableTheme(
        borderColor = "#dfe2e5",
        # stripedColor = "#ecf0f1",
        highlightColor = "#f0f5f9",
        cellPadding = "8px 12px",
      ),
      columns = list(
        CDM_TABLE_NAME = colDef(
          name = "Table Name",
          sortable = FALSE,
          minWidth = 170,
          align = "left",
          footer = "TOTAL",
          aggregated = JS("function(cellInfo) {
                                                 return cellInfo.value
                                                            }")
        ),
        CHECK_NAME = colDef(
          name = "Check Name",
          sortable = FALSE,
          minWidth = 140,
          align = "left",
          aggregated = JS("function(cellInfo) {
                                            return cellInfo.value
                                                     }")
        ),
        CHECK_LEVEL = colDef(
          name = "Check Level",
          sortable = FALSE,
          minWidth = 100,
          align = "left",
          aggregated = JS("function(cellInfo) {
                                             return cellInfo.value
                                                       }")
        ),
        CHECK_DESCRIPTION = colDef(
          name = "Check Description",
          sortable = FALSE,
          minWidth = 140,
          align = "left",
          aggregated = JS("function(cellInfo) {
                                                   return cellInfo.value
                                                             }")
        ),
        FAILED = colDef(
          name = "# Failed",
          align = "center",
          footer =  function(values)
            comma(sum(values), digits = 0),
          aggregate = "sum",
          minWidth = 55,
          sortable = FALSE,
          format =
            colFormat(separators = TRUE, digits = 0)
        ),
        CHECKS = colDef(
          name = "# Checks",
          align = "center",
          footer =  function(values)
            comma(sum(values), digits = 0),
          aggregate = "sum",
          minWidth = 55,
          sortable = FALSE,
          format =
            colFormat(separators = TRUE, digits = 0)
        ),
        PCT_PASSED = colDef(
          name = "% Passed",
          align = "center",
          aggregate = JS(
            "function(values, rows) {
                                            let totalFailed = 0
                                            let totalChecked = 0
                                            rows.forEach(function(row) {
                                            totalFailed += row['FAILED']
                                            totalChecked += row['CHECKS']
                                            })
                                            return (1 - (totalFailed / totalChecked))*100
                                                        }"
          ),
          minWidth = 55,
          sortable = FALSE,
          format =
            colFormat(separators = TRUE, digits = 0)
        ),
        NUM_VIOLATED_ROWS = colDef(
          name = "# Violated Rows",
          align = "center",
          footer =  function(values)
            comma(sum(values), digits = 0),
          aggregate = "sum",
          minWidth = 110,
          sortable = FALSE,
          format =
            colFormat(separators = TRUE, digits = 0)
        ),
        NUM_DENOMINATOR_ROWS = colDef(
          name = "Total # of Rows",
          align = "center",
          footer =  function(values)
            comma(sum(values), digits = 0),
          aggregate = "sum",
          minWidth = 110,
          sortable = FALSE,
          format =
            colFormat(separators = TRUE, digits = 0)
        ),
        PCT_VIOLATED_ROWS = colDef(
          name = "Avg. % Violated",
          align = "center",
          aggregate = JS(
            "function(values, rows) {
                                                   let totalNumerator = 0
                                                   let totalDenominator = 0
                                                   rows.forEach(function(row) {
                                                   totalNumerator += row['NUM_VIOLATED_ROWS']
                                                   totalDenominator += row['NUM_DENOMINATOR_ROWS']})
                                                   return (totalNumerator / totalDenominator)*100}"
          ),
          minWidth = 65,
          sortable = FALSE,
          format =
            colFormat(separators = TRUE, digits = 1)
        ),
        THRESHOLD_VALUE = colDef(
          name = "Max. Threshold Value",
          align = "center",
          footer =  function(values)
            comma(max(values), digits = 0),
          aggregate = "max",
          minWidth = 70,
          sortable = FALSE,
          format =
            colFormat(separators = TRUE, digits = 0)
        ),
        
        CATEGORY = colDef(show = FALSE),
        SUBCATEGORY = colDef(show = FALSE),
        CONTEXT = colDef(show = FALSE),
        checkId = colDef(show = FALSE),
        CHECK_STATUS = colDef(show = FALSE),
        QUERY_TEXT = colDef(show = FALSE),
        SQL_VIOLATED = colDef(show = FALSE),
        ERROR = colDef(show = FALSE),
        NOT_APPLICABLE_REASON = colDef(show = FALSE)
      ),
      
      # pagination = TRUE,
      defaultPageSize = 25,
      height = 850,
      showPageInfo = FALSE,
      wrap = TRUE,
      # resizable = TRUE,
      pagination = FALSE,
      details = colDef(
        name = "",
        details = JS(
          "function(rowInfo)
          {
          return 'Details for row: ' + rowInfo.index + '<pre>' +
          'Status: '.bold() + '\\n' +
          rowInfo.row['CHECK_STATUS']
          + '\\n' +
          'Not applicable reason: '.bold() + '\\n' +
          rowInfo.row['NOT_APPLICABLE_REASON']
          + '\\n' +
          'Error: '.bold() + '\\n' +
          rowInfo.row['ERROR']
          + '\\n' +
          'Data Quality Check SQL: '.bold() +rowInfo.row['QUERY_TEXT']
          + '\\n' +
          'SQL for Violated Rows: '.bold() + '\\n' +
          rowInfo.row['SQL_VIOLATED']
          + '\\n' +
          '</pre>'}"
        ),
        html = TRUE,
        width = 25
      )
    )
  })
  
  ################################################
  #### Panel: CDM SOURCE                     ####
  ################################################
  
  getPageSource <- function() {
    return(includeHTML("CDM_SOURCE.html"))
  }
  output$Source <- renderUI({
    getPageSource()
  })
  
  ################################################
  #### Panel: ABOUT                           ####
  ################################################
  
  getPageAbo <- function() {
    return(includeHTML("About.html"))
  }
  output$Abo <- renderUI({
    getPageAbo()
  })
}
