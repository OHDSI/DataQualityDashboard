library(plyr)
library(dplyr)
library(tidyr)
library(jsonlite)
library(janitor)

jsonFilePath <- "synthea.json"

data <- data.frame(fromJSON(jsonFilePath))

data <- tibble(data)

dataT <- select(data, contains("CheckResults")) %>%
  rename_(.dots = setNames(names(.), gsub("CheckResults.", "", names(.))))

################################################
#### TIBBLE OVERVIEW                        ####
################################################

summaryParts <- function(data_tab, variable) {
  part <-
    select(data_tab,
           c(CATEGORY, CONTEXT, PASSED, FAILED, NOT_APPLICABLE, IS_ERROR)) %>%
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

part1 <- summaryParts(dataT, PASSED)

part1 <- rename(part1, Validation.Pass = Validation) %>%
  rename(Verification.Pass = Verification) %>%
  rename(Total.Pass = Total)

part2 <- summaryParts(dataT, FAILED)

part2 <- rename(part2, Validation.Fail = Validation) %>%
  rename(Verification.Fail = Verification) %>%
  rename(Total.Fail = Total)

part3 <- summaryParts(dataT, NOT_APPLICABLE)

part3 <- rename(part3, Validation.Not_Applicable = Validation) %>%
  rename(Verification.Not_Applicable = Verification) %>%
  rename(Total.Not_Applicable = Total)

part4 <- summaryParts(dataT, IS_ERROR)

part4 <- rename(part4, Validation.Error = Validation) %>%
  rename(Verification.Error = Verification) %>%
  rename(Total.Error = Total)

data1 <- inner_join(part1, part2, by = "CATEGORY")
data1 <- inner_join(data1, part3, by = "CATEGORY")
data1 <- inner_join(data1, part4, by = "CATEGORY")

data1 <-
  mutate(data1, Validation.PctPass = (Validation.Pass / (Validation.Pass + Validation.Fail)) *
           100) %>%
  mutate(Verification.PctPass = (Verification.Pass / (Verification.Pass + Verification.Fail)) *
           100) %>%
  mutate(Total.PctPass = (Total.Pass / (Total.Pass + Total.Fail)) * 100) %>%
  adorn_totals()

data1$Validation.PctPass[4] = (data1$Validation.Pass[4] / (data1$Validation.Pass[4] + data1$Validation.Fail[4])) *
  100
data1$Verification.PctPass[4] = (data1$Verification.Pass[4] / (data1$Verification.Pass[4] + data1$Verification.Fail[4])) *
  100
data1$Total.PctPass[4] = (data1$Total.Pass[4] / (data1$Total.Pass[4] + data1$Total.Fail[4])) *
  100

################################################
#### TIBBLE TABLE CENTRIC PIVOT             ####
################################################

getViolatedRowsQuery <- function(queryText) {
  stringr::str_match(string = queryText, pattern = "(?i)(\\/\\*violatedRowsBegin\\*\\/)(?s)(.*)(\\/\\*violatedRowsEnd\\*\\/)")[3]
}

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
      NOT_APPLICABLE = 0,
      THRESHOLD_VALUE = 0
    )
  ) %>%
  replace_na(list(NUM_DENOMINATOR_ROWS = 1, PASSED = 0)) %>%
  mutate(CHECKS = 1) %>%
  mutate(PCT_PASSED = (PASSED / (PASSED + FAILED)) * 100) %>%
  mutate(PCT_VIOLATED_ROWS = NUM_VIOLATED_ROWS / NUM_DENOMINATOR_ROWS *
           100) %>%
  mutate(CHECK_STATUS = PASSED + 2 * FAILED + 3 * IS_ERROR + 4 * NOT_APPLICABLE) %>%
  mutate(CHECK_LEVEL = recode_factor(
    CHECK_LEVEL,
    TABLE = "Table",
    FIELD = "Field",
    CONCEPT = "Concept"
  )) %>%
  mutate(
    CHECK_STATUS = recode(
      CHECK_STATUS,
      `1` = "Pass",
      `2` = "Fail",
      `3` = "Is Error",
      `4` = "Not Applicable"
    )
  ) %>%
  select(
    !c(
      IS_ERROR,
      NOT_APPLICABLE,
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

DQ_CHECK_SQL <- lapply(dataT$QUERY_TEXT, getViolatedRowsQuery)
DQ_CHECK_SQL_1 <- ldply(DQ_CHECK_SQL)

data2 <- mutate(data2, SQL_VIOLATED = DQ_CHECK_SQL_1$V1) %>%
  relocate(SQL_VIOLATED, .after = last_col()) %>%
  relocate(QUERY_TEXT, .after = last_col())


rm("DQ_CHECK_SQL", "DQ_CHECK_SQL_1")

data2$FAILED <- as.integer(data2$FAILED)
data2$CHECKS <- as.integer(data2$CHECKS)

rm("part1", "part2", "part3", "part4", "data", "dataT")

#write.csv(data, "data3.csv")
