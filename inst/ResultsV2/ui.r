library(shiny)
library(reactable)
library(htmlwidgets)
library(htmltools)
library(formattable)
library(shinyWidgets)
library(shinythemes)
source("load_data_10.R")

ui <- navbarPage(title = div("DATA QUALITY ASSESSMENT",
                             img(src = "ohdsi.png",
                                 height = "50px",
                                 style = "position: absolute;
                                    top: 1px;
                                    right: 15px;")),
              #    tags$head(
              #      tags$style(HTML('.navbar-nav > li > a, .navbar-brand {
              #              padding-top:15px !important; 
              #              padding-bottom:0 !important;
              #              height: 50px;
              #              }
              #             .navbar {min-height:25px !important;}'))
              #   ),
                 
                 theme = shinytheme("flatly"),
                 
                 
                 ################################################
                 #### Panel: OVERVIEW                        ####
                 ################################################
                 
                 tabPanel("OVERVIEW",
                          mainPanel(
                            uiOutput("summary_dt1"),
                            width = 12
                          ),
                 ),
                 
                 
                 ################################################
                 #### Panel: TABLE CENTRIC PIVOT             ####
                 ################################################
                 
                 tabPanel("RESULTS",
                          sidebarLayout(
                            mainPanel(
                              uiOutput("summary_dt2"),
                              width = 10
                            ),
                            sidebarPanel(
                              width = 2,
                              pickerInput(inputId = "cat", 
                                          label = "Category", 
                                          choices = as.vector(unique(data2$CATEGORY)),
                                          multiple = TRUE,
                                          selected = as.vector(unique(data2$CATEGORY)),
                                          options = list(`actions-box` = TRUE)
                              ),
                              pickerInput(inputId = "subcat",
                                          label = "Subcategory",
                                          choices = as.vector(unique(data2$SUBCATEGORY)),
                                          multiple = TRUE,
                                          selected = as.vector(unique(data2$SUBCATEGORY)),
                                          options = list(`actions-box` = TRUE)
                              ),
                              pickerInput(inputId = "cont",
                                          label = "Context",
                                          choices = as.vector(unique(data2$CONTEXT)),
                                          multiple = TRUE,
                                          selected = as.vector(unique(data2$CONTEXT)),
                                          options = list(`actions-box` = TRUE)
                              ),
                              pickerInput(inputId = "check_na",
                                          label = "Check Name",
                                          choices = as.vector(unique(data2$CHECK_NAME)),
                                          multiple = TRUE,
                                          selected = as.vector(unique(data2$CHECK_NAME)),
                                          options = list(`actions-box` = TRUE)
                              ),
                              pickerInput(inputId = "check_le",
                                          label = "Check Level",
                                          choices = as.vector(unique(data2$CHECK_LEVEL)),
                                          multiple = TRUE,
                                          selected = as.vector(unique(data2$CHECK_LEVEL)),
                                          options = list(`actions-box` = TRUE)
                              ),
                              pickerInput(inputId = "check_st",
                                          label = "Check Status",
                                          choices = as.vector(unique(data2$CHECK_STATUS)),
                                          multiple = TRUE,
                                          selected = as.vector(unique(data2$CHECK_STATUS)),
                                          options = list(`actions-box` = TRUE)
                              )
                            ),
                            position = "right"
                          )
                 ),
                 
                 
                 ################################################
                 #### Panel: METATDATA                      ####
                 ################################################
                 
                 tabPanel("CDM SOURCE",
                          fluidPage(htmlOutput("meta"))
                 ),
                 
                 ################################################
                 #### Panel: ABOUT                           ####
                 ################################################
                 
                 tabPanel("ABOUT",
                          fluidPage(htmlOutput("abo"))
                 ),
                 
)
