library(dplyr)
library(tidyverse)
library(stringr)

# Run together with edit_thresholds.R

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
    stop("Not valid value found.")}
  if(!is.null(df) & !is.null(file)){
    stop("Ambiguous input. Give only df or file.")}
  if(!is.null(file)){
      df <- read.csv(file, colClasses = "character", 
                           stringsAsFactors = FALSE, row.names=1)}
  
  # actual pivot_wider
  df_wide <- df %>%
    pivot_wider(
      names_from = Check_name,
      names_sep = "",
      names_glue = "{Check_name}{.value}",
      values_from = c(Threshold, Notes))
  
  return(df_wide)
}


# Get index of rows that fulfill the conditions given in 'file'
# If working well, only one row in 'df' is subset for each row in 'file'
# Prints the corresponding index.
print_threshold_location <- function(df, file){
  
  df_thresholds <- read.csv(file, stringsAsFactors = FALSE)
  df2 <- df %>% mutate(index=c(1:nrow(.)))
  
  for(i in c(1:nrow(df_thresholds))){
    row = df_thresholds[i,]
    
    # for all
    df3 <- df2 %>%
      filter(
        Check_name == row$Check_name &
        cdmTableName == row$cdmTableName)

    # for Field+Concept Level only
    if(tolower(row$Level) %in% c("field", "concept")){
      df3<-df3%>%filter(cdmFieldName == row$cdmFieldName)
    }
    
    # 'additional' auxiliary columns
    if(row$Check_name=="isForeignKey"){
      df3<-df3%>%filter(fkTableName==row$fkTableName)}
    if(row$Check_name=="plausibleGender"){
      df3<-df3%>%filter(conceptId==row$conceptId)}
    if(tolower(row$Level) == "concept" & 
      row$Check_name%in%c("plausibleValueLow", "plausibleValueHigh")){
      df3 <- df3%>%filter(conceptId==row$conceptId &
                        unitConceptId==row$unitConceptId)}
    
    print(paste(row$Check_name, ": ", df3$index, sep=""))
  }
}
