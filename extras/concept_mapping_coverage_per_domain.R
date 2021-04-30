library("dplyr")
library("jsonlite")
library("ggplot2")

path_to_dqd_file <- '/my/path/to/dqd.json'

# Load data
result <- jsonlite::fromJSON(path_to_dqd_file)
check_results <- result$CheckResults %>%
  select(CHECK_NAME, CDM_TABLE_NAME, CDM_FIELD_NAME, 
         NUM_VIOLATED_ROWS, NUM_DENOMINATOR_ROWS, PCT_VIOLATED_ROWS)

# Add fields
coverage_results <- check_results %>%
  filter(CHECK_NAME %in% c("standardConceptRecordCompleteness", "sourceValueCompleteness")) %>%
  filter(!(CDM_TABLE_NAME %in% c("DRUG_ERA", "DOSE_ERA", "CONDITION_ERA"))) %>%
  mutate(
    # Coverage is rows not failing
    coveragePct = 1 - PCT_VIOLATED_ROWS,
    # Standardize domain by taking the base of the field names
    domain = ifelse(CHECK_NAME=="standardConceptRecordCompleteness", 
                      sub('_CONCEPT_ID', '', CDM_FIELD_NAME), 
                      sub('_SOURCE_VALUE', '', CDM_FIELD_NAME)
    ),
    # First check is over all records, second over the unique source terms
    coverageType = recode(CHECK_NAME, 
                   standardConceptRecordCompleteness = "Records",
                   sourceValueCompleteness = "Terms")
  ) %>%
  filter(domain %in% c("VISIT", "PROCEDURE", "DRUG", "CONDITION", "MEASUREMENT", "OBSERVATION"))

# Coverage plot like fig 6 in EHDEN DoA
coverage_results %>%
  ggplot(aes(x=coverageType, y = coveragePct, fill = coverageType)) +
  geom_col() +
  geom_text(aes(label=scales::percent(coveragePct, accuracy = 0.01)), 
            position=position_stack(vjust=0.5), 
            size=3, colour="white") +
  theme(
    axis.text.y=element_text(size=10),
    strip.placement="outside",
    strip.text.y=element_text(angle=90, hjust=0.5, face="bold", size=10,
                              margin=margin(r=0))
  ) +
  coord_flip() +
  facet_grid(domain ~ ., scales="free_y", space="free_y", switch="y") +
  scale_y_continuous(labels = scales::percent) +
  guides(fill=FALSE) +
  ylab("Percentage Coverage (%)") + 
  xlab("") + 
  scale_fill_manual(values=c("darkblue", "skyblue"))
