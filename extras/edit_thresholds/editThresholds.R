# @file editThresholds.R

  
# Pivot longer the csv file, using the check names
# where columns are <check_name>, <check_name>Threshold, or <check_name>Notes
.pivot_longer_func <- function(df){
  df_long <- df %>%
    # Add "_" to help pivot_longer
    rename_with(~ gsub("Threshold", "_Threshold", .x, fixed = TRUE)) %>%
    rename_with(~ gsub("Notes", "_Notes", .x, fixed = TRUE)) %>%
    # bring all (threshold and notes) to a temp column
    pivot_longer(-(!ends_with("Threshold") & !ends_with("Notes")),
                 names_to = c("checkName", "Type"),
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
.pivot_wider_func <- function(df = NULL, file = NULL){
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
      names_from = checkName,
      names_sep = "",
      names_glue = "{checkName}{.value}",
      values_from = c(Threshold, Notes))
  
  return(df_wide)
}


# Get index of rows that fulfill the conditions given in 'file'
# If working well, only one row in 'df' is subset for each row in 'file'
# Prints the corresponding index.
.get_threshold_location <- function(df, row){
  df2 <- df %>% mutate(index=c(1:nrow(.)))
  # for all
  df3 <- df2 %>%
    filter(
      checkName == row$checkName &
        cdmTableName == row$cdmTableName)
  # for Field+Concept Level only
  if(tolower(row$Level) %in% c("field", "concept")){
    df3<-df3%>%filter(cdmFieldName == row$cdmFieldName)
  }
  # 'additional' auxiliary columns
  if(row$checkName=="isForeignKey"){
    df3<-df3%>%filter(fkTableName==row$fkTableName)}
  if(row$checkName=="plausibleGender"){
    df3<-df3%>%filter(conceptId==row$conceptId)}
  if(tolower(row$Level) == "concept" & 
     row$checkName%in%c("plausibleValueLow", "plausibleValueHigh")){
    df3 <- df3%>%filter(conceptId==row$conceptId &
                          unitConceptId==row$unitConceptId)}
  return(df3$index)
}

# Edit threshold in pivoted table
.edit_row <- function(df, index, row){
  # threshold
  df[index, "Threshold"] = row$Threshold
  # notes (avoid duplication)
  notes_old <- as.character(df[index,'Notes'])
  if(notes_old=="character(0)"){notes_old=""}
  notes_old <- stringr::str_replace_all(string=notes_old, row$Notes, "")
  notes_old <- stringr::str_replace_all(notes_old, "[|][|]", "")
  notes_new <- paste(notes_old, row$Notes, sep="|")
  df[index, 'Notes'] = notes_new
  return(df)
}

# Edits one thresholds file (field, concept or table)
.edit_file <- function(file_, thresholds, savingDir){
  # 1) Get longer table
  df <- read.csv(file_, colClasses = "character", stringsAsFactors = FALSE)
  df_long <- .pivot_longer_func(df)
  # 2) Edit thresholds
  for(i in c(1:nrow(thresholds))){
    row = thresholds[i,]
    index <- .get_threshold_location(df_long, row)
    df_long <- .edit_row(df_long, index, row)
  }
  # 3) Get originally wide table
  df_new <- .pivot_wider_func(df=df_long)
  df_new <- df_new[colnames(df)]
  # 4) Save it!
  short_name <- tail((str_split(file_, "/")[[1]]), n=1)
  saving_name <- file.path(savingDir, paste(substr(short_name, 0, (nchar(short_name)-4)), "_new.csv", sep=""))
  dir.create(file.path(savingDir), showWarnings = FALSE)
  write.csv(df_new, saving_name, row.names = FALSE)
  # 5) (optional) final check
  df.old <- read.csv(file_, colClasses = "character", stringsAsFactors = FALSE)
  df.new <- read.csv(saving_name, colClasses = "character", stringsAsFactors = FALSE)
  end <- base::all.equal(df.old, df.new)
  end <- stringr::str_replace(end, "string mismatch", "difference")
  end <- stringr::str_replace(end, "TRUE", "No differences")
  print(end)
}
  

#' Edit DQD thresholds
#' 
#' Reads a table with the description of checks to be edited (see README.md),
#' and edits the threshold files (table, field and concept levels) in accordance.
#' 
#' @param fileThresholds the file containing the description of the checks
#' @param savingDir the path to the folder where the output should be written
#' @param fileField (optional) the file with the thresholds for the field level checks
#' @param fileConcept (optional) the file with the thresholds for the concept level checks
#' @param fileTable (optional) the file with the thresholds for the table level checks
#' @import dplyr
#' @import tidyverse
#' 
#' @author Elena Garcia Lara, Maxim Moinat
#' 
#' @return A new field, concept and/or table file, containing the edited thresholds, depending on the parameters given.
#' @export
#' 
#' @examples 
#' \dontrun{
#'   editThresholds("thresholds_to_add.csv", savingDir="new_files",
#'   fileField="DQD_Field_Level_v5.3.1.txt", fileConcept=̉"DQD_Concept_Level_v5.3.1.txt")
#' }
editThresholds <- function(fileThresholds, savingDir, fileField=NULL, fileConcept=NULL, fileTable=NULL){
  # calls edition for each thresholds file
  df_thresholds <- read.csv(fileThresholds, colClasses="character",stringsAsFactors = FALSE)
  for(level in unique(df_thresholds$Level)){
    print(paste("Editing:", level))
    thresholds = df_thresholds %>% filter(Level==level)
    if(level=="Field"){.edit_file(fileField, thresholds, savingDir)}
    if(level=="Concept"){.edit_file(fileConcept, thresholds, savingDir)}
    if(level=="Table"){.edit_file(fileTable, thresholds, savingDir)}
  }
}
