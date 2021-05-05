library(dplyr)
library(tidyverse)
library(stringr)



# Pivot longer the csv file, using the check names
# where columns are <check_name>, <check_name>Threshold, or <check_name>Notes
pivot_longer_func <- function(file){

  df <- read.csv(file, colClasses = "character", 
                 stringsAsFactors = FALSE)
  
  df_long <- df %>%
    # Add "_" to help pivot_longer
    rename_with(~ gsub("Threshold", "_Threshold", .x, fixed = TRUE)) %>%
    rename_with(~ gsub("Notes", "_Notes", .x, fixed = TRUE)) %>%
    
    # bring all (threshold and notes) to a temp column
    pivot_longer(-(!ends_with("Threshold") & !ends_with("Notes")),
                 names_to = c("Check_name", "Type"),
                 names_sep = "_",
                 values_to="temp"
    ) %>%
    # separate notes and threshold as two different columns
    pivot_wider(
      names_from = "Type",
      values_from = "temp"
    )
  
  return(df_long)
} 


# Pivot wider the edited threshold table
# Reads either the saved file or a df if both functions are called together
# Returns the original threshold table, with edited thresholds
pivot_wider_func <- function(df = NULL, file = NULL){
  # just to make it flexible
  if(is.null(df) & is.null(file)){
    stop("Not valid value found.")
  }
  
  if(!is.null(df) & !is.null(file)){
    stop("Ambiguous input. Give only df or file.")
  }
  
  # actual pivot_wider
  if(!is.null(file)){
      df <- read.csv(file, colClasses = "character", 
                           stringsAsFactors = FALSE, row.names=1)
      }
  
  df_wide <- df %>%
    pivot_wider(
      names_from = Check_name,
      names_sep = "",
      names_glue = "{Check_name}{.value}",
      values_from = c(Threshold, Notes))
  
  return(df_wide)
  
}
  

# Cleaning step
# just to have a tidier .csv file to read manually.
# This file cannot be converted back to 'wider' with the current code!!
clean_func <- function(df_long){
  df_long_clean <- df_long %>%
    # Make thresholds numeric :) -they were character for first pivot_longer
    mutate(Threshold = as.numeric(Threshold)) %>%
    
    # Filtering rows where no check is happening
    filter(!(Check_name == "isRequired" & isRequired == "No")) %>%
          select(-isRequired) %>%
    filter(!(Check_name == "cdmDatatype" & cdmDatatype == "")) %>%  # never occurs
    filter(!(Check_name == "isPrimaryKey" & isPrimaryKey == "No")) %>%
          select(-isPrimaryKey) %>%
    filter(!(Check_name == "isForeignKey" & isForeignKey == "No")) %>% 
          select(-isForeignKey) %>%
    filter(!(Check_name == "fkDomain" & fkDomain=="")) %>%
    filter(!(Check_name == "fkClass" & fkClass=="")) %>%
    filter(!(Check_name == "isStandardValidConcept" & isStandardValidConcept == "No")) %>% 
          select(-isStandardValidConcept) %>%
    filter(!(Check_name == "measureValueCompleteness" & measureValueCompleteness == "No")) %>%
          select(-measureValueCompleteness) %>%
    filter(!(Check_name == "standardConceptRecordCompleteness" & standardConceptRecordCompleteness == "No")) %>%
          select(-standardConceptRecordCompleteness) %>%
    filter(!(Check_name == "sourceConceptRecordCompleteness" & sourceConceptRecordCompleteness == "No")) %>% 
          select(-sourceConceptRecordCompleteness) %>%
    filter(!(Check_name == "sourceValueCompleteness" & sourceValueCompleteness == "No")) %>% 
          select(-sourceValueCompleteness) %>%
    filter(!(Check_name == "plausibleValueLow" & plausibleValueLow=="")) %>%
    filter(!(Check_name == "plausibleValueHigh" & plausibleValueHigh=="")) %>%
    filter(!(Check_name == "plausibleTemporalAfter" & plausibleTemporalAfter=="")) %>% 
          select(-plausibleTemporalAfter) %>%
    filter(!(Check_name == "plausibleDuringLife" & plausibleDuringLife == "No")) %>% 
          select(-plausibleDuringLife) %>%
    
    
    # Keep information only for relevant rows
    mutate(
      cdmDatatype = ifelse(Check_name=="cdmDatatype", cdmDatatype, NA_character_),
      fkClass = ifelse(Check_name == "fkClass", fkClass, NA_character_),
      fkDomain = ifelse(Check_name %in% c("fkDomain", "fkClass", "isRequired"),
                        fkDomain, NA_character_),
      fkTableName = ifelse(
                  Check_name == "isForeignKey", 
                  fkTableName, NA_character_),
      plausibleTemporalAfterFieldName = ifelse(
                  Check_name == "plausibleTemporalAfter",
                  plausibleTemporalAfterFieldName, NA_character_),
      plausibleTemporalAfterTableName = ifelse(
                  Check_name == "plausibleTemporalAfter",
                  plausibleTemporalAfterTableName, NA_character_),
      plausibleValueHigh = ifelse(
                  Check_name == "plausibleValueHigh", 
                  plausibleValueHigh, NA_character_),
      plausibleValueLow = ifelse(
                  Check_name == "plausibleValueLow", 
                  plausibleValueLow, NA_character_)
      
    ) %>%
    
    # Reorder columns
    select(
      Check_name, 
      cdmTableName, cdmFieldName,
      Threshold, Notes,
      fkTableName, fkDomain, fkClass,
      standardConceptFieldName,
      plausibleValueLow, plausibleValueHigh,
      plausibleTemporalAfterTableName, plausibleTemporalAfterFieldName,
      cdmDatatype, 
      fkFieldName,
      userGuidance, etlConventions, runForCohort
    )
  
  return(df_long_clean)
}


print_threshold_location <- function(df, file){
  df_thresholds <- read.csv(file)
  
  df2 <- df %>%
    mutate(index=c(1:nrow(.)))
  
  for(i in c(1:length(df_thresholds))){
    row = df_thresholds[i,]
    df3 <- df2 %>%
      filter(
        Check_name == row$Check_name &
        cdmTableName == row$cdmTableName &
        cdmFieldName == row$cdmFieldName)
    print(df3$index)
  }
    
}


# # How to run:
# # setwd("~/Documents/Projects/EHDEN_UKBiobank/DQD_thresholds_30Apr21/")
# setwd("your/own/dir/xx")
# file <- "DQD_Field_Level_v5.3.1_UKB.csv"
# 
# # 1) get longer table
# df_long <- pivot_longer_func(file)
# write.csv(df_long, file.path(getwd(), "dflong.csv"))
# 
# # 2) Edit thresholds, in df_long directly or in excel file
# # using the following indeces:
# # be aware that the excel file might have one extra row for column names, see the index in the first column!!
# file_thresholds <- "thresholds_to_add.csv"
# print_threshold_location(df_long, file_thresholds)
# 
# # 3) get originally wide table!
# file_edited = "dflong.csv"
# df_new <- pivot_wider_func(file=file_edited)
# # 4) save it!
# 
# write.csv(df_new, file.path(getwd(), "DQD_Field_Level_v5.3.1_new.csv"))
  

