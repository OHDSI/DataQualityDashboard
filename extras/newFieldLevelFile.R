## When updating to support new versions of the CDM, this script helps to create a new version of the field level file. 
## You still need to go in manually and update the thresholds for the new fields added

oldThresholds <- read.csv("inst/csv/OMOP_CDMv5.3.1_Field_Level.csv", 
                          stringsAsFactors = FALSE, na.strings = c(" ",""))

if ("userGuidance" %in% colnames(oldThresholds)) {
  oldThresholds <- oldThresholds %>% 
                   select(-userGuidance)
  
}

if ("etlConventions" %in% colnames(oldThresholds)) {
  oldThresholds <- oldThresholds %>% 
    select(-etlConventions)
  
}

newThresholds <- read.csv("/Users/clairblacketer/Documents/GitHub/CommonDataModel/inst/csv/OMOP_CDMv5.4_Field_Level.csv", 
                          stringsAsFactors = FALSE, na.strings = c(" ",""))

updatedThresholds <- merge(x = newThresholds,
                            y = oldThresholds,
                            by = c("cdmTableName", "cdmFieldName",
                                   "isRequired", "cdmDatatype", "isPrimaryKey",         
                                    "isForeignKey", "fkTableName", "fkFieldName", "fkDomain" ,"fkClass"),
                            all.x = TRUE)

updatedThresholds <- sqldf::sqldf(" 
                                    SELECT cdmTableName, 
                                           cdmFieldName,                               
                                           isRequired,
                                           isRequiredThreshold,
                                           isRequiredNotes,
                                           cdmDatatype,                              
                                           cdmDatatypeThreshold,	cdmDatatypeNotes,	
                                           userGuidance,
                                           etlConventions,
                                           isPrimaryKey,
                                            isPrimaryKeyThreshold,	isPrimaryKeyNotes,isForeignKey,
                                            isForeignKeyThreshold,	isForeignKeyNotes,	fkTableName,
                                            fkFieldName,	fkDomain,	fkDomainThreshold,
                                            fkDomainNotes,	fkClass,	fkClassThreshold,
                                            fkClassNotes,	isStandardValidConcept,	isStandardValidConceptThreshold,
                                            isStandardValidConceptNotes,	measureValueCompleteness,	measureValueCompletenessThreshold,
                                            measureValueCompletenessNotes,	standardConceptRecordCompleteness,	standardConceptRecordCompletenessThreshold,
                                            standardConceptRecordCompletenessNotes,	sourceConceptRecordCompleteness,	sourceConceptRecordCompletenessThreshold,
                                            sourceConceptRecordCompletenessNotes,	sourceValueCompleteness,	sourceValueCompletenessThreshold,
                                            sourceValueCompletenessNotes,	standardConceptFieldName,	plausibleValueLow,
                                            plausibleValueLowThreshold,	plausibleValueLowNotes,	plausibleValueHigh,
                                            plausibleValueHighThreshold,	plausibleValueHighNotes,	plausibleTemporalAfter,
                                            plausibleTemporalAfterTableName,	plausibleTemporalAfterFieldName,	plausibleTemporalAfterThreshold,
                                            plausibleTemporalAfterNotes,	plausibleDuringLife	,plausibleDuringLifeThreshold,
                                            plausibleDuringLifeNotes,	runForCohort	
                                      FROM updatedThresholds
                           ")

write.csv(updatedThresholds, file = "inst/csv/OMOP_CDMv5.4_Field_Level.csv", na = "", row.names = FALSE)

## Think about a function to go through and loop through values from v5.3 and put them in v5.4