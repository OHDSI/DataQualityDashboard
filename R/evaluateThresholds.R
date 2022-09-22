#' Internal function to evaluate the data quality checks against given thresholds.
#' 
#' @param checkResults              A dataframe containing the results of the data quality checks
#' @param tableChecks               A dataframe containing the table checks
#' @param fieldChecks               A dataframe containing the field checks
#' @param conceptChecks             A dataframe containing the concept checks
#' 
#' @keywords internal
#' 

.evaluateThresholds <- function(checkResults,
                                tableChecks,
                                fieldChecks,
                                conceptChecks) {
  
  checkResults$FAILED <- 0
  checkResults$PASSED <- 0
  checkResults$IS_ERROR <- 0
  checkResults$NOT_APPLICABLE <- 0
  checkResults$NOT_APPLICABLE_REASON <- NA
  checkResults$THRESHOLD_VALUE <- NA
  checkResults$NOTES_VALUE <- NA
  
  for (i in 1:nrow(checkResults)) {
    thresholdField <- sprintf("%sThreshold", checkResults[i,]$CHECK_NAME)
    notesField <- sprintf("%sNotes", checkResults[i,]$CHECK_NAME)
    
    # find if field exists -----------------------------------------------
    thresholdFieldExists <- eval(parse(text = 
                                         sprintf("'%s' %%in%% colnames(%sChecks)", 
                                                 thresholdField, 
                                                 tolower(checkResults[i,]$CHECK_LEVEL))))
    
    if (!thresholdFieldExists) {
      thresholdValue <- NA
      notesValue <- NA
    } else {
      if (checkResults[i,]$CHECK_LEVEL == "TABLE") {
        
        thresholdFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                                   thresholdField, checkResults[i,]$CDM_TABLE_NAME)
        notesFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                               notesField, checkResults[i,]$CDM_TABLE_NAME)
        
      } else if (checkResults[i,]$CHECK_LEVEL == "FIELD") {
        
        thresholdFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
                                   thresholdField, 
                                   checkResults[i,]$CDM_TABLE_NAME,
                                   checkResults[i,]$CDM_FIELD_NAME)
        notesFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
                               notesField, 
                               checkResults[i,]$CDM_TABLE_NAME,
                               checkResults[i,]$CDM_FIELD_NAME)
        
        
      } else if (checkResults[i,]$CHECK_LEVEL == "CONCEPT") {
        
        if (is.na(checkResults[i,]$UNIT_CONCEPT_ID)) {
          
          thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s]",
                                     thresholdField, 
                                     checkResults[i,]$CDM_TABLE_NAME,
                                     checkResults[i,]$CDM_FIELD_NAME,
                                     checkResults[i,]$CONCEPT_ID)
          notesFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s]",
                                 notesField, 
                                 checkResults[i,]$CDM_TABLE_NAME,
                                 checkResults[i,]$CDM_FIELD_NAME,
                                 checkResults[i,]$CONCEPT_ID)
        } else {
          
          thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
                                     thresholdField, 
                                     checkResults[i,]$CDM_TABLE_NAME,
                                     checkResults[i,]$CDM_FIELD_NAME,
                                     checkResults[i,]$CONCEPT_ID,
                                     as.integer(checkResults[i,]$UNIT_CONCEPT_ID))
          notesFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
                                 notesField, 
                                 checkResults[i,]$CDM_TABLE_NAME,
                                 checkResults[i,]$CDM_FIELD_NAME,
                                 checkResults[i,]$CONCEPT_ID,
                                 as.integer(checkResults[i,]$UNIT_CONCEPT_ID))
        } 
      }
      
      thresholdValue <- eval(parse(text = thresholdFilter))
      notesValue <- eval(parse(text = notesFilter))
      
      checkResults[i,]$THRESHOLD_VALUE <- thresholdValue
      checkResults[i,]$NOTES_VALUE <- notesValue
    }
    
    if (!is.na(checkResults[i,]$ERROR)) {
      checkResults[i,]$IS_ERROR <- 1
    } else if (is.na(thresholdValue) | thresholdValue == 0) {
      # If no threshold, or threshold is 0%, then any violating records will cause this check to fail
      if (!is.na(checkResults[i,]$NUM_VIOLATED_ROWS) & checkResults[i,]$NUM_VIOLATED_ROWS > 0) {
        checkResults[i,]$FAILED <- 1
      }
    } else if (checkResults[i,]$PCT_VIOLATED_ROWS * 100 > thresholdValue) {
      checkResults[i,]$FAILED <- 1  
    }
  }
  
  missingTables <- dplyr::select(
    dplyr::filter(checkResults, CHECK_NAME == "cdmTable" & FAILED == 1), 
    CDM_TABLE_NAME)
  if (nrow(missingTables) > 0) {
    missingTables$TABLE_IS_MISSING <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, missingTables, by = "CDM_TABLE_NAME"), 
      TABLE_IS_MISSING = ifelse(CHECK_NAME != "cdmTable" & IS_ERROR == 0, TABLE_IS_MISSING, NA))
  } else {
    checkResults$TABLE_IS_MISSING <- NA
  }
  
  missingFields <- dplyr::select(
    dplyr::filter(checkResults, CHECK_NAME == "cdmField" & FAILED == 1 & is.na(TABLE_IS_MISSING)), 
    CDM_TABLE_NAME, CDM_FIELD_NAME)
  if (nrow(missingFields) > 0) {
    missingFields$FIELD_IS_MISSING <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, missingFields, by = c("CDM_TABLE_NAME", "CDM_FIELD_NAME")), 
      FIELD_IS_MISSING = ifelse(CHECK_NAME != "cdmField" & IS_ERROR == 0, FIELD_IS_MISSING, NA))
  } else {
    checkResults$FIELD_IS_MISSING <- NA
  }
  
  emptyTables <- dplyr::distinct(
    dplyr::select(
      dplyr::filter(checkResults, CHECK_NAME == "measureValueCompleteness" & 
                      NUM_DENOMINATOR_ROWS == 0 & 
                      IS_ERROR == 0 &
                      is.na(TABLE_IS_MISSING) & 
                      is.na(FIELD_IS_MISSING)), 
      CDM_TABLE_NAME))
  if (nrow(emptyTables) > 0) {
    emptyTables$TABLE_IS_EMPTY <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, emptyTables, by = c("CDM_TABLE_NAME")), 
      TABLE_IS_EMPTY = ifelse(CHECK_NAME != "cdmField" & CHECK_NAME != "cdmTable" & IS_ERROR == 0, TABLE_IS_EMPTY, NA))
  } else {
    checkResults$TABLE_IS_EMPTY <- NA
  }
  
  emptyFields <- 
    dplyr::select(
      dplyr::filter(checkResults, CHECK_NAME == "measureValueCompleteness" & 
                      NUM_DENOMINATOR_ROWS == NUM_VIOLATED_ROWS & 
                      is.na(TABLE_IS_MISSING) & is.na(FIELD_IS_MISSING) & is.na(TABLE_IS_EMPTY)), 
      CDM_TABLE_NAME, CDM_FIELD_NAME)
  if (nrow(emptyFields) > 0) {
    emptyFields$FIELD_IS_EMPTY <- 1
    checkResults <- dplyr::mutate(
      dplyr::left_join(checkResults, emptyFields, by = c("CDM_TABLE_NAME", "CDM_FIELD_NAME")), 
      FIELD_IS_EMPTY = ifelse(CHECK_NAME != "measureValueCompleteness" & CHECK_NAME != "cdmField" & CHECK_NAME != "isRequired" & IS_ERROR == 0, FIELD_IS_EMPTY, NA))
  } else {
    checkResults$FIELD_IS_EMPTY <- NA
  }
  
  checkResults <- dplyr::mutate(
    checkResults,
    CONCEPT_IS_MISSING = ifelse(
      IS_ERROR == 0 &
        is.na(TABLE_IS_MISSING) & 
        is.na(FIELD_IS_MISSING) & 
        is.na(TABLE_IS_EMPTY) & 
        is.na(FIELD_IS_EMPTY) & 
        CHECK_LEVEL == "CONCEPT" &
        is.na(UNIT_CONCEPT_ID) &
        NUM_DENOMINATOR_ROWS == 0,
      1,
      NA
    )
  )
  
  checkResults <- dplyr::mutate(
    checkResults,
    CONCEPT_AND_UNIT_ARE_MISSING = ifelse(
      IS_ERROR == 0 &
        is.na(TABLE_IS_MISSING) & 
        is.na(FIELD_IS_MISSING) & 
        is.na(TABLE_IS_EMPTY) & 
        is.na(FIELD_IS_EMPTY) & 
        CHECK_LEVEL == "CONCEPT" &
        !is.na(UNIT_CONCEPT_ID) &
        NUM_DENOMINATOR_ROWS == 0,
      1,
      NA
    )
  )
  
  checkResults <- dplyr::mutate(
    checkResults, 
    NOT_APPLICABLE = dplyr::coalesce(TABLE_IS_MISSING, FIELD_IS_MISSING, TABLE_IS_EMPTY, FIELD_IS_EMPTY, CONCEPT_IS_MISSING, CONCEPT_AND_UNIT_ARE_MISSING, 0), 
    NOT_APPLICABLE_REASON = dplyr::case_when(
      !is.na(TABLE_IS_MISSING) ~ sprintf("Table %s does not exist.", CDM_TABLE_NAME), 
      !is.na(FIELD_IS_MISSING) ~ sprintf("Field %s.%s does not exist.", CDM_TABLE_NAME, CDM_FIELD_NAME), 
      !is.na(TABLE_IS_EMPTY) ~ sprintf("Table %s is empty.", CDM_TABLE_NAME),
      !is.na(FIELD_IS_EMPTY) ~ sprintf("Field %s.%s is not populated.", CDM_TABLE_NAME, CDM_FIELD_NAME), 
      !is.na(CONCEPT_IS_MISSING) ~ sprintf("%s=%s is missing from the %s table.", CDM_FIELD_NAME, CONCEPT_ID, CDM_TABLE_NAME),
      !is.na(CONCEPT_AND_UNIT_ARE_MISSING) ~ sprintf("Combination of %s=%s, UNIT_CONCEPT_ID=%s and VALUE_AS_NUMBER IS NOT NULL is missing from the %s table.", CDM_FIELD_NAME, CONCEPT_ID, UNIT_CONCEPT_ID, CDM_TABLE_NAME)
    )
  )
  
  checkResults <- dplyr::select(checkResults, -c(TABLE_IS_MISSING, FIELD_IS_MISSING, TABLE_IS_EMPTY, FIELD_IS_EMPTY, CONCEPT_IS_MISSING, CONCEPT_AND_UNIT_ARE_MISSING))
  checkResults <- dplyr::mutate(checkResults, FAILED = ifelse(NOT_APPLICABLE == 1, 0, FAILED))
  checkResults <- dplyr::mutate(checkResults, PASSED = ifelse(FAILED == 0 & IS_ERROR == 0 & NOT_APPLICABLE == 0, 1, 0))
  
  checkResults
}
