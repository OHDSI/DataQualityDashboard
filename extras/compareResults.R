library("dplyr")
library("jsonlite")
library("ggplot2")
library("plotly")

# Directories
setwd('/my/path/to/dqd/extra/scripts/')
file_old <- "json/results/folder/file1.json"
file_new <- "json/results/folder/file2.json"
saving_dir <- "results_compare/"
dir.create(file.path(getwd(), saving_dir), showWarnings = FALSE)


# List all differences
# ... between OLD
result_old <- jsonlite::fromJSON(file_old)
check_results_old <- tibble(result_old$CheckResults)

# ... and NEW
result_new <- jsonlite::fromJSON(file_new)
check_results_new <- tibble(result_new$CheckResults)

# ... only keep the different
combined_results <- check_results_old %>%
  left_join(check_results_new,
            by=c("CHECK_NAME", "CDM_TABLE_NAME", "CDM_FIELD_NAME",
                 "CONCEPT_ID", "UNIT_CONCEPT_ID"),
            suffix=c(".old", ".new")) %>%
  filter(PCT_VIOLATED_ROWS.old != PCT_VIOLATED_ROWS.new)

# Save as csv
write.csv(combined_results, file=file.path(getwd(), saving_dir, "different_checks.csv"))

# Plot
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
               sprintf('<br><i>Check ID: </i>%s', checkId.new),
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
                      values = c("chocolate1", "darkblue"))+
  scale_alpha(guide = 'none') +
  theme_minimal() +
  theme(legend.title = element_blank()) +
  expand_limits(y=100, x=100) +
  labs(x="Previous % of row fails", y="Current % of row fails") +
  annotate("text",label="Improved", x = 88.5, y = 12.5, colour="grey") +
  annotate("text",label="Worsened", x = 12.5, y = 88.5, colour="grey")

p_interactive <- ggplotly(p, tooltip="text") %>%
  style(hoveron="text")

htmlwidgets::saveWidget(p_interactive, file.path(getwd(), saving_dir, "fig_compare_DQD.html"))
p_interactive