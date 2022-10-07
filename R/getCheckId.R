
#' Internal function to define the id of each check.
#' 
#' @param checkLevel                The level of the check. Options are table, field, or concept
#' @param checkName                 The name of the data quality check
#' @param cdmTableName              The name of the CDM data table the quality check is applied to
#' @param cdmFieldName              The name of the field in the CDM data table the quality check is applied to
#' @param conceptId                 The concept id the quality check is applied to
#' @param unitConceptId             The unit concept id the quality check is applied to
#' 
#' @keywords internal
#' @importFrom stats na.omit
#'

.getCheckId <- function(checkLevel, 
                        checkName, 
                        cdmTableName,
                        cdmFieldName = NA, 
                        conceptId = NA,
                        unitConceptId = NA) {
  tolower(
    paste(
      na.omit(c(
        dplyr::na_if(gsub(" ", "", checkLevel), ""), 
        dplyr::na_if(gsub(" ", "", checkName), ""), 
        dplyr::na_if(gsub(" ", "", cdmTableName), ""), 
        dplyr::na_if(gsub(" ", "", cdmFieldName), ""), 
        dplyr::na_if(gsub(" ", "", conceptId), ""), 
        dplyr::na_if(gsub(" ", "", unitConceptId), "")
      )), 
      collapse = "_"
    )
  )
}
