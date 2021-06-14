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

check_results_old <- result_old$CheckResults %>%
  select(checkId, CHECK_NAME, 
         CDM_TABLE_NAME, CDM_FIELD_NAME, CONCEPT_ID, UNIT_CONCEPT_ID,
         THRESHOLD_VALUE, PCT_VIOLATED_ROWS,
         FAILED)

# ... and NEW
result_new <- jsonlite::fromJSON(file_new)

check_results_new <- result_new$CheckResults %>%
  select(checkId, CHECK_NAME, 
         CDM_TABLE_NAME, CDM_FIELD_NAME, CONCEPT_ID, UNIT_CONCEPT_ID,
         THRESHOLD_VALUE, PCT_VIOLATED_ROWS,
         FAILED) %>%
  rename(new_PCT_VIOLATED_ROWS = PCT_VIOLATED_ROWS)

# ... only keep the different
combined_results <- tibble(check_results_old) %>%
  left_join(check_results_new, by=c("CDM_TABLE_NAME", "CDM_FIELD_NAME",
                                    "CHECK_NAME", "CONCEPT_ID", "UNIT_CONCEPT_ID")) %>%
  filter(PCT_VIOLATED_ROWS != new_PCT_VIOLATED_ROWS)

# Save as csv
write.csv(combined_results, file=file.path(getwd(), saving_dir, "different_checks.csv"))


# Plot them - interactive
p <- combined_results %>%
  mutate(       
    # Otherwise legend names are overwritten by ggplotly
    fails = ifelse(FAILED.y==0, "Pass", "Fail"),
    # for aesthetic of labels
    pct_old = round(PCT_VIOLATED_ROWS*100, digits=2),
    pct_new = round(new_PCT_VIOLATED_ROWS*100, digits=2)
  ) %>% 
  ggplot(aes(x=PCT_VIOLATED_ROWS*100, y=new_PCT_VIOLATED_ROWS*100,
             colour=fails,
             text=paste(
               sprintf('<br><i>Check ID: </i>%s', checkId.y),
               sprintf('<br><i>Check name: </i>%s', CHECK_NAME),
               sprintf('<br><i>Table: </i>%s', CDM_TABLE_NAME),
               sprintf('<br><i>Field: </i>%s', CDM_FIELD_NAME),
               sprintf('<br><i>Threshold value: </i>%.1f%%', THRESHOLD_VALUE.y),
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
  labs(x="Previous % of row fails", y="Current % of row fails") +
  expand_limits(y=100, x=100) +
  annotate("text",label="Improved", x = 90, y = 10, colour="grey") +
  annotate("text",label="Worsened", x = 10, y = 90, colour="grey")


p2 <- ggplotly(p, tooltip="text") %>%
  style(hoveron="text")

htmlwidgets::saveWidget(p2, file.path(getwd(), saving_dir,"fig_compare_DQD.html"))
p2