#' Compare DQD results
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
#' @param savingDir the path to the folder where the output should be written
#' 
#' @author Elena Garcia Lara
#' @author Maxim Moinat
#' 
#' @return An interactive plotly figure or nothing if no differences are found.
#' @export
#' 
#' @examples 
#' \dontrun{
#'   compareDqResults("dqd_results_1.json", "dqd_results_2.json", "output")
#' }
compareDqResults <- function(jsonPath.old, jsonPath.new, savingDir){
  
  # List all differences
  # ... between OLD
  result_old <- jsonlite::fromJSON(jsonPath.old)
  check_results_old <- tibble(result_old$CheckResults)
  
  # ... and NEW
  result_new <- jsonlite::fromJSON(jsonPath.new)
  check_results_new <- tibble(result_new$CheckResults)
  
  # ... only keep the different
  combined_results <- check_results_old %>%
    left_join(check_results_new,
              by=c("CHECK_NAME", "CDM_TABLE_NAME", "CDM_FIELD_NAME",
                   "CONCEPT_ID", "UNIT_CONCEPT_ID"),
              suffix=c(".old", ".new")) %>%
    filter(PCT_VIOLATED_ROWS.old != PCT_VIOLATED_ROWS.new)
  
  # When No difference found, exit function
  if(nrow(combined_results)==0){
    stop("No differences found.")
  }
  
  # Save as csv
  saving_name <- file.path(savingDir, paste("compare_dqd", Sys.Date(), sep="_"))
  dir.create(file.path(savingDir), showWarnings = FALSE)
  write.csv(combined_results, file=paste(saving_name, ".csv", sep=""))
  
  # Visualization
  p <- combined_results %>%
    mutate(       
      fail_status = ifelse(FAILED.new==0, "Pass", "Fail"),
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
    scale_colour_manual(labels = c("Fail", "Pass"), 
                        values = c("Pass" = "darkblue", "Fail" = "chocolate1"))+
    scale_alpha(guide = 'none') +
    theme_minimal() +
    theme(legend.title = element_blank()) +
    lims(y=c(0,100), x=c(0,100)) +
    labs(x="Previous % of row fails", y="Current % of row fails") +
    annotate("text", label="Improved", x = 88.5, y = 12.5, colour="grey") +
    annotate("text", label="Worsened", x = 12.5, y = 88.5, colour="grey")
  
  p_interactive <- plotly::ggplotly(p, tooltip="text") %>%
    plotly::style(hoveron="text")
  
  htmlwidgets::saveWidget(p_interactive, file=paste(saving_name, ".html", sep=""))
  p_interactive
}

#' Plot concept mapping coverage
#' 
#' Finds mapping coverage from a given DQD results file, and returns an accessible figure
#' If \code{savingDir} is provided, the figure is saved as png.
#' 
#' @param jsonPath the path to the DQD json results file
#' @param savingDir the path to the folder where the output should be written
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
