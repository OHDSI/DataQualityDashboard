library(dplyr)
library(tidyverse)
library(stringr)

# Read the current threshold file
# setwd("~/Documents/Projects/EHDEN_UKBiobank/DQD_thresholds_30Apr21/")
setwd("your/own/dir/xx")
file <- "DQD_Field_Level_v5.3.1_UKB.csv"
result <- read.csv(file, 
                   colClasses = "character", stringsAsFactors = FALSE)

# List all check types
check_list <- c(
  "cdmDatatype",
  # "cdmField", # yes check, where tho?
  "fkClass", "fkDomain",
  "isForeignKey", "isPrimaryKey", "isRequired",
  # "measurePersonCompleteness",# yes check, where tho?
  "measureValueCompleteness",
  "plausibleDuringLife",
  # "plausibleGender", # yes check, where tho?
  "plausibleTemporalAfter",
  "plausibleValueHigh", "plausibleValueLow",
  "sourceConceptRecordCompleteness", "sourceValueCompleteness",
  "standardConceptRecordCompleteness",
  "isStandardValidConcept" # yes check, where tho?
)


# Pivot longer the csv file, using the check names
# where columns are <check_name>, <check_name>Threshold, or <check_name>Notes
df <- result %>%
  # unite("index", c(cdmTableName,cdmFieldName)) %>%
  # Add "_" to help pivot_longer
  rename_with(~ gsub("Threshold", "_Threshold", .x, fixed = TRUE)) %>%
  rename_with(~ gsub("Notes", "_Notes", .x, fixed = TRUE))

# The pivoting
df_long <- df %>%
  pivot_longer(-(!ends_with("Threshold") & !ends_with("Notes")),
               names_to = c("Check_name", "Type"),
               names_sep = "_",
               values_to="temp"
  ) %>%
  pivot_wider(
    names_from = "Type",
    values_from = "temp"
  ) %>%
  
  # Make thresholds numeric :)
  mutate(Threshold = as.numeric(Threshold)) %>%

  # Cleaning step
  # (filtering rows where no check is happening)
  
  # -when commented out code in this chunk, i modified the filter
  # to not remove rows but put values as NA below, think that's the correct thing? --
  
  # --fkclass reads in fkClass--
  filter(!(Check_name == "fkClass" & fkClass=="")) %>%
  # filter(!(!Check_name == "fkClass" & !fkClass=="")) %>%
  # --fkDomain reads in fkDomain--
  filter(!(Check_name == "fkDomain" & fkDomain=="")) %>%
  # filter(!(!Check_name %in% c("fkDomain", "fkClass", "isRequired") & !fkDomain=="")) %>%
  # --isForeignKey reads in fkTableName--
  filter(!(Check_name == "isForeignKey" & isForeignKey == "No")) %>% select(-isForeignKey) %>%
  # filter(!(!Check_name == "isForeignKey" & !fkTableName=="")) %>%
  #
  filter(!(Check_name == "isPrimaryKey" & isPrimaryKey == "No")) %>% select(-isPrimaryKey) %>%
  # fkdomain isrequired
  filter(!(Check_name == "isRequired" & isRequired == "No")) %>% select(-isRequired) %>%
  #
  filter(!(Check_name == "measureValueCompleteness" & measureValueCompleteness == "No")) %>% select(-measureValueCompleteness) %>%
  filter(!(Check_name == "plausibleDuringLife" & plausibleDuringLife == "No")) %>% select(-plausibleDuringLife) %>%
  
  # plausibleTemporalAfterFieldName, plausibleTemporalAfterTableName
  filter(!(Check_name == "plausibleTemporalAfter" & plausibleTemporalAfter=="")) %>% select(-plausibleTemporalAfter) %>%
  # filter(!(!Check_name == "plausibleTemporalAfter" & !plausibleTemporalAfterFieldName=="")) %>%
  # filter(!(!Check_name == "plausibleTemporalAfter" & !plausibleTemporalAfterTableName=="")) %>%
  
  
  # plausibleGender
  # ???
  
  # plaus val plaus val
  filter(!(Check_name == "plausibleValueHigh" & plausibleValueHigh=="")) %>%
  # filter(!(!Check_name == "plausibleValueHigh" & !plausibleValueHigh=="")) %>%
  filter(!(Check_name == "plausibleValueLow" & plausibleValueLow=="")) %>%
  # filter(!(!Check_name == "plausibleValueLow" & !plausibleValueLow=="")) %>%
  #
  filter(!(Check_name == "sourceConceptRecordCompleteness" & sourceConceptRecordCompleteness == "No")) %>% select(-sourceConceptRecordCompleteness) %>%
  filter(!(Check_name == "sourceValueCompleteness" & sourceValueCompleteness == "No")) %>% select(-sourceValueCompleteness) %>%
  filter(!(Check_name == "standardConceptRecordCompleteness" & standardConceptRecordCompleteness == "No")) %>% select(-standardConceptRecordCompleteness) %>%
  filter(!(Check_name == "isStandardValidConcept" & isStandardValidConcept == "No")) %>% select(-isStandardValidConcept) %>%
  
  
  # (keep information only for relevant rows)
  mutate(
    cdmDatatype = ifelse(Check_name=="cdmDatatype", cdmDatatype, NA_character_),
    fkClass = ifelse(Check_name == "fkClass", fkClass, NA_character_),
    fkDomain = ifelse(Check_name %in% c("fkDomain", "fkClass", "isRequired"),
                      fkDomain, NA_character_),
    fkTableName = ifelse(Check_name == "isForeignKey", fkTableName, NA_character_),
    plausibleTemporalAfterFieldName = ifelse(
                Check_name == "plausibleTemporalAfter",
                plausibleTemporalAfterFieldName, NA_character_),
    plausibleTemporalAfterTableName = ifelse(
                Check_name == "plausibleTemporalAfter",
                plausibleTemporalAfterTableName, NA_character_),
    plausibleValueHigh = ifelse(Check_name == "plausibleValueHigh", plausibleValueHigh, NA_character_),
    plausibleValueLow = ifelse(Check_name == "plausibleValueLow", plausibleValueLow, NA_character_)
    
  )
  
# Reorder columns
df_long <- df_long %>%
  select(
    Check_name, 
    cdmTableName, cdmFieldName,
    Threshold, Notes,
    fkTableName, fkDomain, fkClass,
    standardConceptFieldName,
    plausibleValueLow, plausibleValueHigh,
    plausibleTemporalAfterTableName, plausibleTemporalAfterFieldName,
    cdmDatatype, fkFieldName,
    userGuidance, etlConventions, runForCohort
  )

write.csv(df_long, file.path(getwd(), "long_table.csv"))
  


