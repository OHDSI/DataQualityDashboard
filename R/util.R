# @file util.R
#
# Copyright 2021 Observational Health Data Sciences and Informatics
#
# This file is part of DataQualityDashboard
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Joins two DQD results
#' 
#' @param jsonPath.1 the path to the first DQD json results file
#' @param jsonPath.2 the path to the second DQD json results file
#' 
#' @return A tibble with the joined dqd results, one row per DQD check.
.joinDqdResults <- function(jsonPath.1, jsonPath.2, suffixes = c(".1", ".2")){
  # List all differences
  # ... between OLD
  result_old <- jsonlite::fromJSON(jsonPath.1)
  check_results_old <- tibble(result_old$CheckResults)
  
  # ... and NEW
  result_new <- jsonlite::fromJSON(jsonPath.2)
  check_results_new <- tibble(result_new$CheckResults)
  
  # ... and join
  combined_results <- check_results_old %>%
    left_join(check_results_new,
              by=c("CHECK_NAME", "CDM_TABLE_NAME", "CDM_FIELD_NAME",
                   "CONCEPT_ID", "UNIT_CONCEPT_ID"),
              suffix=suffixes)
  
  return(combined_results)
}

#' Create an interactive scatter plot comparing two DQD results
#' 
#' Matches checks from the two provided DQD results and saves two outputs:
#' \itemize{
#'  \item a table with all checks that are different
#'  \item an interactive plot (html) with old fail percentage versus new fail
#'  percentage
#' } 
#' This makes it easy to identify differences between subsequent runs of DQD.
#' Nothing will be created if there are no differences between the given DQD results.
#' See also: \link[TBD]{TBD - link to abstract}
#' 
#' @param jsonPath.old the path to the old DQD json results file
#' @param jsonPath.new the path to the new DQD json results file
#' @param savingDir (optional) the path to the folder where the output should be written.
#'                  if not given, no output will be written.
#' 
#' @author Elena Garcia Lara
#' @author Maxim Moinat
#' 
#' @return An interactive plotly figure or nothing if no differences are found.
#' @export
#' 
#' @examples 
#' \dontrun{
#'   plotCompareDqdResults("dqd_results_1.json", "dqd_results_2.json", "output")
#' }
plotCompareDqdResults <- function(jsonPath.old, jsonPath.new, savingDir = NA){
  combinedResult <- .joinDqdResults(jsonPath.old, jsonPath.new, suffixes = c(".old", ".new"))
  
  # Only keep changed
  combinedResult <- combinedResult %>%
                      filter(PCT_VIOLATED_ROWS.old != PCT_VIOLATED_ROWS.new)
  
  # When no difference found, exit function
  if(nrow(combinedResult)==0){
    stop("No differences found.")
  }
  
  # Visualization
  p <- combinedResult %>%
    mutate(       
      fail_status = ifelse(FAILED.old, 
                           ifelse(FAILED.new, "Fail-to-Fail", "Fail-to-Pass"),
                           ifelse(FAILED.new, "Pass-to-Fail", "Pass-to-Pass")
                           ),
      pct_old = round(PCT_VIOLATED_ROWS.old*100, digits=2),
      pct_new = round(PCT_VIOLATED_ROWS.new*100, digits=2)
    ) %>% 
    ggplot(aes(x=pct_old,
               y=pct_new,
               colour=fail_status,
               text=paste(
                 sprintf('<br><i>Check name: </i>%s', CHECK_NAME),
                 sprintf('<br><i>Table: </i>%s', CDM_TABLE_NAME),
                 sprintf('<br><i>Field: </i>%s', CDM_FIELD_NAME),
                 sprintf('<br><i>Threshold value: </i>%.1f%%', THRESHOLD_VALUE.new),
                 sprintf('<br><b><i>old: </i> %.2f%% </b>', pct_old),
                 sprintf('<br><b><i>new: </i> %.2f%% </b>', pct_new)
               ), alpha=0.6)) +
    geom_point() +
    geom_abline(colour="gray", linetype = "dashed")+
    scale_colour_manual(labels = c("Fail→Pass", "Fail→Fail", "Pass→Pass", "Pass→Fail"),
                        values = c("Pass→Pass" = "lightblue", "Fail→Fail" = "chocolate1",
                                   "Fail→Pass" = "darkblue", "Pass→Fail" = "coral"))+
    scale_alpha(guide = 'none') +
    theme_minimal() +
    theme(legend.title = element_blank()) +
    lims(y=c(0,100), x=c(0,100)) +
    labs(x="Previous % of row fails", y="Current % of row fails") +
    annotate("text", label="Improved", x = 88.5, y = 12.5, colour="grey") +
    annotate("text", label="Worsened", x = 12.5, y = 88.5, colour="grey")
  
  p_interactive <- plotly::ggplotly(p, tooltip="text") %>%
    plotly::style(hoveron="text")
  
  if (!is.na(savingDir)) {
    savingName <- file.path(savingDir, paste("compare_dqd", Sys.Date(), sep="_"))
    dir.create(file.path(savingDir), showWarnings = FALSE)
    htmlwidgets::saveWidget(p_interactive, file=paste(savingName, ".html", sep=""))
  }
  
  p_interactive
}

#' Create table comparing two DQD results
#' 
#' @param jsonPath.old the path to the old DQD json results file
#' @param jsonPath.new the path to the new DQD json results file
#' @param savingDir (optional) the path to the folder where the output should be written
#'                  if not given, no output will be written.
#' 
#' @author Elena Garcia Lara
#' @author Maxim Moinat
#' 
#' @return An overview of all differing checks
#' @export
#' 
#' @examples 
#' \dontrun{
#'   tableCompareDqdResults("dqd_results_1.json", "dqd_results_2.json", "output")
#' }
tableCompareDqdResults <- function(jsonPath.old, jsonPath.new, savingDir = NA){
  combinedResult <- .joinDqdResults(jsonPath.old, jsonPath.new, suffixes = c(".old", ".new"))
  
  # Only keep changed
  combinedResult <- combinedResult %>%
    filter(PCT_VIOLATED_ROWS.old != PCT_VIOLATED_ROWS.new) %>%
    select(CHECK_NAME, CDM_TABLE_NAME, CDM_FIELD_NAME,
           CONCEPT_ID, UNIT_CONCEPT_ID,
           PCT_VIOLATED_ROWS.old, NUM_DENOMINATOR_ROWS.old, FAILED.old,
           PCT_VIOLATED_ROWS.new, NUM_DENOMINATOR_ROWS.new, FAILED.new,
           NOTES_VALUE.old, NOTES_VALUE.new)
  
  # Save as csv
  if (!is.na(savingDir)) {
    saving_name <- file.path(savingDir, paste("compare_dqd", Sys.Date(), sep="_"))
    dir.create(file.path(savingDir), showWarnings = FALSE)
    write.csv(combinedResult, file=paste(saving_name, ".csv", sep=""))
  }
  
  return(combinedResult)
}

#' Plot concept mapping coverage
#' 
#' Finds mapping coverage from a given DQD results file, and returns an accessible figure
#' If \code{savingDir} is provided, the figure is saved as png.
#' 
#' @param jsonPath the path to the DQD json results file
#' @param savingDir (optional) the path to the folder where plot and data table are written
#'                  if not given, no output will be saved
#' 
#' @import dplyr
#' @import ggplot2
#' 
#' @author Elena Garcia Lara
#' @author Maxim Moinat
#' 
#' @return A figure to visualize concept mapping coverage per domain
#' @export
#' 
#' @examples 
#' \dontrun{
#'   plotConceptCoverage("dqd_results.json", "output")
#' }
plotConceptCoverage <- function(jsonPath, savingDir = NA){
  
  # Load data
  result <- jsonlite::fromJSON(jsonPath)
  check_results <- result$CheckResults %>%
    select(CHECK_NAME, CDM_TABLE_NAME, CDM_FIELD_NAME, 
           NUM_VIOLATED_ROWS, NUM_DENOMINATOR_ROWS, PCT_VIOLATED_ROWS)
  
  coverage_results <- check_results %>%
    filter(CHECK_NAME %in% c("standardConceptRecordCompleteness", "sourceValueCompleteness")) %>%
    # Not interested in era's as these are all derived
    filter(!(CDM_TABLE_NAME %in% c("DRUG_ERA", "DOSE_ERA", "CONDITION_ERA"))) %>%
    mutate(
      CDM_FIELD_NAME = toupper(CDM_FIELD_NAME),
      # First check is over all records, second over the unique source terms
      coverageType = recode(CHECK_NAME, 
                            standardConceptRecordCompleteness = "Records",
                            sourceValueCompleteness = "Terms"),
      # Coverage is rows not failing
      coveragePct = 1 - PCT_VIOLATED_ROWS,
      # Naming of domains
      domain = gsub("_(OCC\\w+|EXP\\w+|PLAN.+)$", "", CDM_TABLE_NAME),
      variable = ifelse(CHECK_NAME=="standardConceptRecordCompleteness", 
                        sub('_CONCEPT_ID', '', CDM_FIELD_NAME), 
                        sub('_SOURCE_VALUE', '', CDM_FIELD_NAME)
      ),
      domain_abbrev = recode(domain, 
                             VISIT = "VST",
                             CONDITION = "COND",
                             PROCEDURE = "PROC",
                             OBSERVATION = "OBS",
                             MEASUREMENT = "MEAS",
                             SPECIMEN = "SPEC"
      ),
      domainField = ifelse(domain==variable,
                           domain,
                           paste0(domain_abbrev,"-",variable)
      )
    )
  
  # Table
  table <- coverage_results %>% 
    mutate(
      percentUnmapped = scales::percent(PCT_VIOLATED_ROWS, accuracy = 0.01),
      nUnmapped = formatC(NUM_VIOLATED_ROWS, format="d", big.mark=","),
      nTotal = formatC(NUM_DENOMINATOR_ROWS, format="d", big.mark=",")
    ) %>%
    select(domainField, coverageType, percentUnmapped, nUnmapped, nTotal) %>% 
    arrange(domainField, desc(coverageType))  # by domain, terms first, then records
  
  # Coverage plot like fig 6 in EHDEN DoA
  # note: coverage is percentage NOT failing to map
  fig <- coverage_results %>%
    # To keep things simple, we only look at the six main domains and units
    filter(domainField %in% c("VISIT", "PROCEDURE", "DRUG", "CONDITION", "MEASUREMENT", 
                              "OBSERVATION", "MEAS-UNIT", "OBS-UNIT"),
           NUM_DENOMINATOR_ROWS > 0
    ) %>%
    mutate(
      coveragePct = 1 - PCT_VIOLATED_ROWS
    ) %>%
    ggplot(aes(x=coverageType, y = coveragePct, fill = coverageType)) +
    geom_col() +
    geom_text(aes(label=scales::percent(coveragePct, accuracy = 0.01)), 
              position=position_stack(vjust=0.5), 
              size=3, colour="gray10", fontface="bold") +
    theme_minimal() +
    theme(
      axis.text.y=element_text(size=10),
      strip.placement="outside",
      strip.text.y=element_text(angle=0, hjust=0.5, face="bold", size=6)
    ) +
    coord_flip() +
    facet_grid(domainField ~ ., scales="free_y", space="free_y", switch="y") +
    guides(fill=FALSE) +
    ylab("Percentage Coverage (%)") + 
    xlab("") + 
    scale_fill_manual(values=c("cornflowerblue", "skyblue"))
  
  if (!is.na(savingDir)) {
    saving_name <- file.path(savingDir, paste("concept_mapping_coverage", Sys.Date(), sep="_"))
    dir.create(file.path(savingDir), showWarnings = FALSE)
    ggsave(filename=paste(saving_name, ".png", sep=""), height = 8, width = 8 * 1.61803)
    saving_table <- file.path(savingDir, "concept_mapping_coverage.csv")
    write.csv(table, file=saving_table, row.names = FALSE)
  }
  
  return(fig)
}
