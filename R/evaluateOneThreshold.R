
#' Internal function to evaluate one threshold
#' @noRd
#' @keywords internal
#' TODO: NA and IS_ERROR
.evaluateOneThreshold <- function(check_name,
                                  check_level,
                                  cdm_table_name,
                                  cdm_field_name,
                                  concept_id,
                                  unit_concept_id,
                                  tableChecks,
                                  fieldChecks,
                                  conceptChecks) {
  thresholdField <- sprintf("%sThreshold", check_name)
  
  # find if field exists -----------------------------------------------
  thresholdFieldExists <- eval(parse(
    text = sprintf("'%s' %%in%% colnames(%sChecks)", 
                     thresholdField, 
                     tolower(check_level)
  )))
  
  if (!thresholdFieldExists) {
    thresholdValue <- NA
  } else {
    if (check_level == "TABLE") {
      thresholdFilter <- sprintf("tableChecks$%s[tableChecks$cdmTableName == '%s']",
                                 thresholdField, cdm_table_name)
      
    } else if (check_level == "FIELD") {
      thresholdFilter <- sprintf("fieldChecks$%s[fieldChecks$cdmTableName == '%s' &
                                fieldChecks$cdmFieldName == '%s']",
                                 thresholdField, 
                                 cdm_table_name,
                                 cdm_field_name)
    } else if (check_level == "CONCEPT") {
      if (is.na(unit_concept_id)) {
        thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s]",
                                   thresholdField, 
                                   cdm_table_name,
                                   cdm_field_name,
                                   concept_id)
      } else {
        thresholdFilter <- sprintf("conceptChecks$%s[conceptChecks$cdmTableName == '%s' &
                                  conceptChecks$cdmFieldName == '%s' &
                                  conceptChecks$conceptId == %s &
                                  conceptChecks$unitConceptId == '%s']",
                                   thresholdField, 
                                   cdm_table_name,
                                   cdm_field_name,
                                   concept_id,
                                   as.integer(unit_concept_id))
      }
    }
    thresholdValue <- eval(parse(text = thresholdFilter))
  }
  
  # Need value of 0 for NA in generated SQL
  if (is.na(thresholdValue)) {
    thresholdValue <- 0
  }
  
  thresholdValue
}