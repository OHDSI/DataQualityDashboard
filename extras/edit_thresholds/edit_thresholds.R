library(dplyr)
library(tidyverse)
library(stringr)

# Directories
setwd("your/own/dir/xx")
file <- file.path(getwd(), "DQD_Field_Level_v5.3.1.txt")
file_new <- file.path(getwd(), "DQD_Field_Level_v5.3.1_new.csv")
file_thresholds <- file.path(getwd(), "thresholds_to_add.csv")



# Pivot longer the csv file, using the check names
# where columns are <check_name>, <check_name>Threshold, or <check_name>Notes
pivot_longer_func <- function(df){
  
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
get_threshold_location <- function(df, row){
  
    df2 <- df %>% mutate(index=c(1:nrow(.)))
    
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
    
    # print(paste(row$Check_name, ": ", df3$index, sep=""))
    return(df3$index)
}

# Edit threshold
edit_threshold <- function(df, index, row){
  
  # threshold
  df[index, "Threshold"] = row$Threshold
  
  # notes (avoid duplication)
  notes_old <- as.character(df[index,'Notes'])
  notes_old <- stringr::str_replace_all(string=notes_old, row$Notes, "")
  notes_old <- stringr::str_replace_all(notes_old, "[character(0)]", "")
  notes_old <- stringr::str_replace_all(notes_old, "[|][|]", "")
  notes_new <- paste(notes_old, row$Notes, sep="|")
  df[index, 'Notes'] = notes_new
  
  return(df)
  
}

# Main function
# 1) get longer table
df <- read.csv(file, colClasses = "character", stringsAsFactors = FALSE)
df_long <- pivot_longer_func(df)
df_thresholds <- read.csv(file_thresholds, colClasses="character",stringsAsFactors = FALSE)

# 2) Edit thresholds
for(i in c(1:nrow(df_thresholds))){
  row = df_thresholds[i,]
  index <- get_threshold_location(df_long, row)
  df_long <- edit_threshold(df_long, index, row)
}

# 3) get originally wide table
df_new <- pivot_wider_func(df=df_long)
df_new <- df_new[colnames(df)]

# 4) save it!
write.csv(df_new, file_new, row.names = FALSE)

# 5) (optional) final check
df.old <- read.csv(file, colClasses = "character", stringsAsFactors = FALSE)
df.new <- read.csv(file_new, colClasses = "character", stringsAsFactors = FALSE)
end <-base::all.equal(df.old, df.new)
stringr::str_replace(end, "string mismatch", "difference")
