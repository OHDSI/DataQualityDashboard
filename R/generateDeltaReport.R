library(dplyr)

priorResultsFile <- "D:/OHDSI/Ares/public/data/NJ/20211205/dq-result.json"
currentResultsFile <- "D:/OHDSI/Ares/public/data/NJ/20220202/dq-result.json"

formatData <- function(dataFrame,includeDelta=FALSE) {
  if (includeDelta) {
    temp <- dataFrame[,c("CATEGORY.y","CDM_TABLE_NAME.y", "CHECK_NAME.y", "CHECK_LEVEL.y", "CDM_FIELD_NAME.y","PCT_VIOLATED_ROWS.y","THRESHOLD_VALUE.y", "DELTA")]
    colnames(temp) <- c("Category","CDM Table","Check Name","Check Level","Field Name","% Violated", "% Threshold", "Delta")    
    return(temp)    
  } else {
    temp <- dataFrame[,c("CATEGORY.y","CDM_TABLE_NAME.y", "CHECK_NAME.y", "CHECK_LEVEL.y", "CDM_FIELD_NAME.y","PCT_VIOLATED_ROWS.y","THRESHOLD_VALUE.y")]
    colnames(temp) <- c("Category","CDM Table","Check Name","Check Level","Field Name","% Violated", "% Threshold")    
    return(temp)    
  }
}

compareDataQualityResults <- function(priorResultFile, currentResultFile) {
  results <- {}
  
  prior <- jsonlite::fromJSON(priorResultsFile)
  current <- jsonlite::fromJSON(currentResultsFile) 
  
  priorResults <- prior$CheckResults
  currentResults <- current$CheckResults
  
  mergedResults <- priorResults %>% left_join(currentResults, by = c("checkId"))
  
  newIssues <- mergedResults %>% filter(FAILED.x == 0 & FAILED.y == 1)
  results$newIssues <- formatData(newIssues)
  
  fixedIssues <- mergedResults %>% filter(FAILED.x == 1 & FAILED.y == 0)
  results$fixedIssues <- formatData(fixedIssues)
  
  improvingIssues <- mergedResults %>% filter(FAILED.x == 1 & FAILED.y == 1 & PCT_VIOLATED_ROWS.x > PCT_VIOLATED_ROWS.y) %>% mutate(DELTA=PCT_VIOLATED_ROWS.y - PCT_VIOLATED_ROWS.x)
  results$improvingIssues <- formatData(improvingIssues, TRUE)
  
  arisingIssues <- mergedResults %>% filter(FAILED.x == 0 & FAILED.y == 0 & PCT_VIOLATED_ROWS.x < PCT_VIOLATED_ROWS.y) %>% mutate(DELTA=PCT_VIOLATED_ROWS.y - PCT_VIOLATED_ROWS.x)
  results$arisingIssues <- formatData(arisingIssues, TRUE)

  overview <- data.frame(
    "Summary" = c("New Issues", "Fixed Issues", "Improving Issues", "Arising Issues"),
    "Count" = c(nrow(newIssues), nrow(fixedIssues), nrow(improvingIssues), nrow(arisingIssues))
  )
  
  results$overview <- overview
  
  return(results)
}

results <- compareDataQualityResults(priorResultsFile, currentResultsFile)
rmarkdown::render("extras/dqdelta.rmd", params=list(results=results))

