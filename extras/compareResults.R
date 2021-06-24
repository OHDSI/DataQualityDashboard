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
#' @param saving_dir the path to the folder where the output should be written
#' @import dplyr
#' @import ggplot2
#' @importFrom plotly ggplotly
#' @importFrom plotly style
#' @importFrom htmlwidgets saveWidget
#' @importFrom jsonlite fromJSON
#' 
#' @author Elena Garcia Lara, Maxim Moinat
#' 
#' @return An interactive plotly figure or nothing if no differences are found.
#' @export
#' 
#' @examples 
#' \dontrun{
#'   compareDqResults("dqd_results_1.json", "dqd_results_2.json", "output")
#' }
library("dplyr")
library("ggplot2")
# Other packages used: jsonlite, plotly

compareDqResults <- function(jsonPath.old, jsonPath.new, saving_dir){

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
  
  # Save as csv
  saving_name <- file.path(saving_dir, paste("compare_dqd", Sys.Date(), sep="_"))
  dir.create(file.path(saving_dir), showWarnings = FALSE)
  write.csv(combined_results, file=paste(saving_name, ".csv", sep=""))
  
  # No difference found, exit function
  if(nrow(combined_results)==0){
    stop("No differences found.")
  }
  
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
