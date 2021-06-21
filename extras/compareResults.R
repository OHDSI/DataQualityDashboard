#' Comparing DQD results
#' 
#' Use:
#' compare_results(file_old, file_new, saving_dir)

library("dplyr")
# Other packages used: jsonlite, ggplot2, plotly

compare_results <- function(jsonPath.old, jsonPath.new, saving_dir){
  # List all differences
  # ... between OLD
  result_old <- jsonlite::fromJSON(jsonPath.old)
  check_results_old <- dplyr::tibble(result_old$CheckResults)
  
  # ... and NEW
  result_new <- jsonlite::fromJSON(jsonPath.new)
  check_results_new <- dplyr::tibble(result_new$CheckResults)
  
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
  
  # If no differences: return
  if(nrow(combined_results)==0){
    stop("No differences found.")
  }
  
  ### Visualization
  p <- combined_results %>%
    mutate(       
      fail_status = ifelse(FAILED.new==0, "Pass", "Fail"),
      pct_old = round(PCT_VIOLATED_ROWS.old*100, digits=2),
      pct_new = round(PCT_VIOLATED_ROWS.new*100, digits=2)
    ) %>% 
    ggplot2::ggplot(ggplot2::aes(x=pct_old,
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
    ggplot2::geom_point() +
    ggplot2::geom_abline(colour="gray", linetype = "dashed")+
    ggplot2::scale_colour_manual(labels = c("Fail", "Pass"), 
                        values = c("chocolate1", "darkblue"))+
    ggplot2::scale_alpha(guide = 'none') +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.title = ggplot2::element_blank()) +
    ggplot2::lims(y=c(0,100), x=c(0,100)) +
    ggplot2::labs(x="Previous % of row fails", y="Current % of row fails") +
    ggplot2::annotate("text",label="Improved", x = 88.5, y = 12.5, colour="grey") +
    ggplot2::annotate("text",label="Worsened", x = 12.5, y = 88.5, colour="grey")
  
  p_interactive <- plotly::ggplotly(p, tooltip="text") %>%
    plotly::style(hoveron="text")
  
  htmlwidgets::saveWidget(p_interactive, file=paste(saving_name, ".html", sep=""))
  p_interactive
}
