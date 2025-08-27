# Copyright 2025 Observational Health Data Sciences and Informatics
#
# This file is part of DataQualityDashboard
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
