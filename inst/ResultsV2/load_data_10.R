library(plyr)
library(dplyr)
library(tidyr)
library(jsonlite)
library(janitor)

jsonFilePath <- Sys.getenv("jsonPath")

data <- data.frame(fromJSON(jsonFilePath))

data <- tibble(data)

dataT <- select(data, contains("CheckResults")) %>%
  rename_(.dots = setNames(names(.), gsub("CheckResults.", "", names(.)))) %>%
  rename(any_of(c(N.A. = "NOT_APPLICABLE"))) # any_of(C()) works even if a
# variable does not exists
# https://stackoverflow.com/questions/68965823/rename-only-if-field-exists-otherwise-ignore

################################################
#### TIBBLE OVERVIEW                        ####
################################################

summaryParts1 <- function(data_tab, variable) {
  part <-
    select(data_tab,
           c(CATEGORY, CONTEXT, PASSED, FAILED, N.A., IS_ERROR)) %>%
    mutate(CATEGORY = as.factor(CATEGORY)) %>%
    mutate(CONTEXT = as.factor(CONTEXT)) %>%
    group_by(CATEGORY, CONTEXT) %>%
    dplyr::summarise("sum" := sum({
      {
        variable
      }
    })) %>%
    spread(CONTEXT, sum) %>%
    ungroup() %>%
    mutate(Total = Validation + Verification)
}

summaryParts2Sum <- function(data_tab, variable) {
  part <-
    select(data_tab,
           c(CATEGORY, CONTEXT, FAILED)) %>%
    mutate(CATEGORY = as.factor(CATEGORY)) %>%
    mutate(CONTEXT = as.factor(CONTEXT)) %>%
    group_by(CATEGORY, CONTEXT) %>%
    dplyr::summarise("sum" := sum({
      {
        variable
      }
    })) %>%
    spread(CONTEXT, sum) %>%
    ungroup()
}

summaryParts2Count <- function(data_tab) {
  part <-
    select(data_tab,
           c(CATEGORY, CONTEXT, FAILED)) %>%
    mutate(CATEGORY = as.factor(CATEGORY)) %>%
    mutate(CONTEXT = as.factor(CONTEXT)) %>%
    group_by(CATEGORY, CONTEXT) %>%
    dplyr::summarise("count" := n()) %>%
    spread(CONTEXT, count) %>%
    ungroup()
}

# Checks if a string is in column name
# https://stackoverflow.com/questions/60978376/r-to-identify-whether-column-names-in-a-dataframe-contains-string
checkString <- function(dat, pat)
  any(grepl(pat, dat$CONTEXT))



  if ("N.A." %in% colnames(dataT)) {
    part1 <- summaryParts1(dataT, PASSED)
    
    part1 <- dplyr::rename(part1, Validation.Pass = Validation) %>%
      dplyr::rename(Verification.Pass = Verification) %>%
      dplyr::rename(Total.Pass = Total)
    
    part2 <- summaryParts1(dataT, FAILED)
    
    part2 <- dplyr::rename(part2, Validation.Fail = Validation) %>%
      dplyr::rename(Verification.Fail = Verification) %>%
      dplyr::rename(Total.Fail = Total)
    
    part3 <- summaryParts1(dataT, N.A.)
    
    part3 <- dplyr::rename(part3, Validation.N.A. = Validation) %>%
      dplyr::rename(Verification.N.A. = Verification) %>%
      dplyr::rename(Total.N.A. = Total)
    
    part4 <- summaryParts1(dataT, IS_ERROR)
    
    part4 <- dplyr::rename(part4, Validation.Error = Validation) %>%
      dplyr::rename(Verification.Error = Verification) %>%
      dplyr::rename(Total.Error = Total)
    
    data1 <- inner_join(part1, part2, by = "CATEGORY")
    data1 <- inner_join(data1, part3, by = "CATEGORY")
    data1 <- inner_join(data1, part4, by = "CATEGORY")
    
    data1 <-
      mutate(data1, Validation.PctPass = (Validation.Pass / (Validation.Pass + Validation.Fail)) *
               100) %>%
      mutate(Verification.PctPass = (
        Verification.Pass / (Verification.Pass + Verification.Fail)
      ) *
        100) %>%
      mutate(Total.PctPass = (Total.Pass / (Total.Pass + Total.Fail)) * 100) %>%
      adorn_totals()
    
    data1$Validation.PctPass[4] = (
      data1$Validation.Pass[4] / (data1$Validation.Pass[4] + data1$Validation.Fail[4])) *
      100
    data1$Verification.PctPass[4] = (
      data1$Verification.Pass[4] / (data1$Verification.Pass[4] + data1$Verification.Fail[4])
    ) *
      100
    data1$Total.PctPass[4] = (data1$Total.Pass[4] / (data1$Total.Pass[4] + data1$Total.Fail[4])) *
      100
    
  } else {
    part1 <- summaryParts2Sum(dataT, FAILED)
    part2 <- summaryParts2Count(dataT)
    
    part1 <- dplyr::rename(part1, Validation.Fail = Validation) %>%
      dplyr::rename(Verification.Fail = Verification)
    
    part2 <- dplyr::rename(part2, Validation.Total = Validation) %>%
      dplyr::rename(Verification.Total = Verification)
    
    data1 <- inner_join(part1, part2, by = "CATEGORY")
    
    data1 <-
      mutate(data1,
             Validation.Pass = (Validation.Total - Validation.Fail)) %>%
      mutate(Verification.Pass = (Verification.Total - Verification.Fail)) %>%
      mutate(Total.Pass = Verification.Pass + Validation.Pass) %>%
      mutate(Total.Fail = Verification.Fail + Validation.Fail) %>%
      mutate(Total = Total.Pass + Total.Fail) %>%
      mutate(Validation.PctPass = (Validation.Pass / (Validation.Pass + Validation.Fail)) * 100) %>%
      mutate(Verification.PctPass = (
        Verification.Pass / (Verification.Pass + Verification.Fail)
      ) * 100) %>%
      mutate(Total.PctPass = (Total.Pass / (Total.Pass + Total.Fail)) * 100) %>%
      select(!c(Validation.Total, Verification.Total, Total)) %>%
      adorn_totals()
    
    data1$Validation.PctPass[4] = (
      data1$Validation.Pass[4] / (data1$Validation.Pass[4] + data1$Validation.Fail[4])) *
      100
    data1$Verification.PctPass[4] = (
      data1$Verification.Pass[4] / (data1$Verification.Pass[4] + data1$Verification.Fail[4])
    ) *
      100
    data1$Total.PctPass[4] = (data1$Total.Pass[4] / (data1$Total.Pass[4] + data1$Total.Fail[4])) *
      100
    
  }

################################################
#### TIBBLE TABLE CENTRIC PIVOT             ####
################################################

getViolatedRowsQuery <- function(queryText) {
  stringr::str_match(string = queryText, pattern = "(?i)(\\/\\*violatedRowsBegin\\*\\/)(?s)(.*)(\\/\\*violatedRowsEnd\\*\\/)")[3]
}


  if ("N.A." %in% colnames(dataT)) {
    data2 <- mutate(dataT, CATEGORY = factor(CATEGORY)) %>%
      mutate(SUBCATEGORY = if_else(SUBCATEGORY == "", "None", SUBCATEGORY)) %>%
      mutate(SUBCATEGORY = factor(SUBCATEGORY)) %>%
      mutate(CONTEXT = factor(CONTEXT)) %>%
      mutate(CHECK_NAME = factor(CHECK_NAME)) %>%
      mutate(CHECK_LEVEL = factor(CHECK_LEVEL)) %>%
      replace_na(
        list(
          NUM_VIOLATED_ROWS = 0,
          PCT_VIOLATED_ROWS = 0,
          FAILED = 0,
          IS_ERROR = 0,
          N.A. = 0,
          THRESHOLD_VALUE = 0
        )
      ) %>%
      replace_na(list(NUM_DENOMINATOR_ROWS = 1, PASSED = 0)) %>%
      mutate(CHECKS = 1) %>%
      mutate(PCT_PASSED = (PASSED / (PASSED + FAILED)) * 100) %>%
      mutate(PCT_VIOLATED_ROWS = NUM_VIOLATED_ROWS / NUM_DENOMINATOR_ROWS *
               100) %>%
      mutate(CHECK_STATUS = PASSED + 2 * FAILED + 3 * IS_ERROR + 4 * N.A.) %>%
      mutate(CHECK_LEVEL = recode_factor(
        CHECK_LEVEL,
        TABLE = "Table",
        FIELD = "Field",
        CONCEPT = "Concept"
      )) %>%
      mutate(CHECK_STATUS = recode(
        CHECK_STATUS,
        `1` = "Pass",
        `2` = "Fail",
        `3` = "Is Error",
        `4` = "N.A."
      )) %>%
      select(
        !c(
          IS_ERROR,
          N.A.,
          PASSED,
          EXECUTION_TIME,
          SQL_FILE,
          CONCEPT_ID,
          UNIT_CONCEPT_ID,
          CDM_FIELD_NAME
        )
      ) %>%
      relocate(
        CDM_TABLE_NAME,
        CHECK_NAME,
        checkId,
        CHECK_DESCRIPTION,
        CHECK_STATUS,
        CATEGORY,
        SUBCATEGORY,
        CONTEXT,
        CHECK_LEVEL,
        FAILED,
        CHECKS,
        PCT_PASSED,
        NUM_VIOLATED_ROWS,
        NUM_DENOMINATOR_ROWS,
        PCT_VIOLATED_ROWS,
        THRESHOLD_VALUE
      )
  } else {
    data2 <- mutate(dataT, CATEGORY = factor(CATEGORY)) %>%
      mutate(SUBCATEGORY = if_else(SUBCATEGORY == "", "None", SUBCATEGORY)) %>%
      mutate(SUBCATEGORY = factor(SUBCATEGORY)) %>%
      mutate(CONTEXT = factor(CONTEXT)) %>%
      mutate(CHECK_NAME = factor(CHECK_NAME)) %>%
      mutate(CHECK_LEVEL = factor(CHECK_LEVEL)) %>%
      replace_na(
        list(
          NUM_VIOLATED_ROWS = 0,
          PCT_VIOLATED_ROWS = 0,
          FAILED = 0,
          IS_ERROR = 0,
          N.A. = 0,
          THRESHOLD_VALUE = 0
        )
      ) %>%
      replace_na(list(NUM_DENOMINATOR_ROWS = 1, PASSED = 0)) %>%
      mutate(CHECKS = 1) %>%
      mutate(PASSED = (CHECKS - FAILED)) %>%
      mutate(PCT_PASSED = (PASSED / CHECKS) * 100) %>%
      mutate(PCT_VIOLATED_ROWS = NUM_VIOLATED_ROWS / NUM_DENOMINATOR_ROWS *
               100) %>%
      mutate(CHECK_STATUS = PASSED + 2 * FAILED) %>%
      mutate(CHECK_LEVEL = recode_factor(
        CHECK_LEVEL,
        TABLE = "Table",
        FIELD = "Field",
        CONCEPT = "Concept"
      )) %>%
      mutate(CHECK_STATUS = recode(
        CHECK_STATUS,
        `1` = "Pass",
        `2` = "Fail"
      )) %>%
      select(
        !c(
          PASSED,
          EXECUTION_TIME,
          SQL_FILE,
          CONCEPT_ID,
          UNIT_CONCEPT_ID,
          CDM_FIELD_NAME
        )
      ) %>%
      relocate(
        CDM_TABLE_NAME,
        CHECK_NAME,
        checkId,
        CHECK_DESCRIPTION,
        CHECK_STATUS,
        CATEGORY,
        SUBCATEGORY,
        CONTEXT,
        CHECK_LEVEL,
        FAILED,
        CHECKS,
        PCT_PASSED,
        NUM_VIOLATED_ROWS,
        NUM_DENOMINATOR_ROWS,
        PCT_VIOLATED_ROWS,
        THRESHOLD_VALUE
      )
  }

DQ_CHECK_SQL <- lapply(dataT$QUERY_TEXT, getViolatedRowsQuery)
DQ_CHECK_SQL_1 <- ldply(DQ_CHECK_SQL)

data2 <- mutate(data2, SQL_VIOLATED = DQ_CHECK_SQL_1$V1) %>%
  relocate(SQL_VIOLATED, .after = last_col()) %>%
  relocate(QUERY_TEXT, .after = last_col())


rm("DQ_CHECK_SQL", "DQ_CHECK_SQL_1")

data2$FAILED <- as.integer(data2$FAILED)
data2$CHECKS <- as.integer(data2$CHECKS)

#write.csv(data, "data3.csv")
