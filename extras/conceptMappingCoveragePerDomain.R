#' Comparing DQD results
#' 
#' Use:
#' plot_concept_coverage(jsonPath)

library("dplyr")
library("ggplot2")
# Other packages used: jsonlite

plot_conncept_coverage <- function(jsonPath){
  
  # Load data
  result <- jsonlite::fromJSON(jsonPath)
  check_results <- result$CheckResults %>%
    select(CHECK_NAME, CDM_TABLE_NAME, CDM_FIELD_NAME, 
           NUM_VIOLATED_ROWS, NUM_DENOMINATOR_ROWS, PCT_VIOLATED_ROWS)
  
  coverage_results <- check_results %>%
    filter(CHECK_NAME %in% c("standardConceptRecordCompleteness", "sourceValueCompleteness")) %>%
    # Not interested in era's as these are all derived
    filter(!(CDM_TABLE_NAME %in% c("DRUG_ERA", "DOSE_ERA", "CONDITION_ERA"))) %>%
    mutate(
      CDM_FIELD_NAME = toupper(CDM_FIELD_NAME),
      # First check is over all records, second over the unique source terms
      coverageType = recode(CHECK_NAME, 
                            standardConceptRecordCompleteness = "Records",
                            sourceValueCompleteness = "Terms"),
      # Coverage is rows not failing
      coveragePct = 1 - PCT_VIOLATED_ROWS,
      # Naming of domains
      domain = gsub("_(OCC\\w+|EXP\\w+|PLAN.+)$", "", CDM_TABLE_NAME),
      variable = ifelse(CHECK_NAME=="standardConceptRecordCompleteness", 
                        sub('_CONCEPT_ID', '', CDM_FIELD_NAME), 
                        sub('_SOURCE_VALUE', '', CDM_FIELD_NAME)
      ),
      domain_abbrev = recode(domain, 
                             VISIT = "VST",
                             CONDITION = "COND",
                             PROCEDURE = "PROC",
                             OBSERVATION = "OBS",
                             MEASUREMENT = "MEAS",
                             SPECIMEN = "SPEC"
      ),
      domainField = ifelse(domain==variable,
                           domain,
                           paste0(domain_abbrev,"-",variable)
     )
    )
  
  # Table
  table <- coverage_results %>% 
    mutate(
      percentUnmapped = scales::percent(PCT_VIOLATED_ROWS, accuracy = 0.01),
      nUnmapped = formatC(NUM_VIOLATED_ROWS, format="d", big.mark=","),
      nTotal = formatC(NUM_DENOMINATOR_ROWS, format="d", big.mark=",")
    ) %>%
    select(domainField, coverageType, percentUnmapped, nUnmapped, nTotal) %>% 
    arrange(domainField, desc(coverageType))  # by domain, terms first, then records
  
  write.csv(table, file="concept_mapping_coverage.csv", row.names = FALSE)
  
  # Coverage plot like fig 6 in EHDEN DoA
  # note: coverage is percentage NOT failing to map
  fig <- coverage_results %>%
    # To keep things simple, we only look at the six main domains and units
    filter(domainField %in% c("VISIT", "PROCEDURE", "DRUG", "CONDITION", "MEASUREMENT", 
                         "OBSERVATION", "MEAS-UNIT", "OBS-UNIT")
    ) %>%
    mutate(
      coveragePct = 1 - PCT_VIOLATED_ROWS
    ) %>%
    ggplot(aes(x=coverageType, y = coveragePct, fill = coverageType)) +
    geom_col() +
    geom_text(aes(label=scales::percent(coveragePct, accuracy = 0.01)), 
              position=position_stack(vjust=0.5), 
              size=3, colour="gray10", fontface="bold") +
    theme_minimal() +
    theme(
      axis.text.y=element_text(size=10),
      strip.placement="outside",
      strip.text.y=element_text(angle=0, hjust=0.5, face="bold", size=6)
    ) +
    coord_flip() +
    facet_grid(domainField ~ ., scales="free_y", space="free_y", switch="y") +
    guides(fill=FALSE) +
    ylab("Percentage Coverage (%)") + 
    xlab("") + 
    scale_fill_manual(values=c("cornflowerblue", "skyblue"))
  
  ggsave('concept_mapping_coverage.png', height = 8, width = 8 * 1.61803)
}
