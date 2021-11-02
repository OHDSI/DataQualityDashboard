# Function to take a CDM 5.3.1 field level threshold file and update it to work with CDM 5.4

thresholdFileUpdate <- function(locationFieldLevel531 = './inst/csv/OMOP_CDMv5.3.1_Field_Level.csv',
                                locationFieldLevel54 = './inst/csv/OMOP_CDMv5.4_Field_Level.csv',
                                locationNewFieldLevel154 = './inst/csv/CustomThreshold_OMOP_CDMv5.4_Field_Level.csv') {

library(dplyr)

# pull field_level.csv into data frames
fieldLevel531 <- read.csv(locationFieldLevel531)
fieldLevel54 <- read.csv(locationFieldLevel54)

# Reviews and loops through each table name and field name combination in the 5.4 Field level CSV
for(i in 1:nrow(fieldLevel54)){
  
  currentTable <- fieldLevel54$cdmTableName[i]
  currentField <- fieldLevel54$cdmFieldName[i]
  
  # Identifies the corresponding table name and field name combination within the 5.3 field level CSV
  for(j in 1:nrow(fieldLevel531)){

    # If a match is found in the 5.3 field level file, update all related attributes (columns) within the file.
    if(currentTable == fieldLevel531$cdmTableName[j] & currentField == fieldLevel531$cdmFieldName[j]){
      
      fieldLevel54$etlConventions[i] <- fieldLevel531$etlConventions[j]
      fieldLevel54$isPrimaryKeyNotes[i] <- fieldLevel531$isPrimaryKeyNotes[j]
      fieldLevel54$isForeignKeyNotes[i] <- fieldLevel531$isForeignKeyNotes[j]
      fieldLevel54$fkDomain[i] <- fieldLevel531$fkDomain[j]
      fieldLevel54$fkClass[i] <- fieldLevel531$fkClass[j]
      fieldLevel54$isStandardValidConcept[i] <- fieldLevel531$isStandardValidConcept[j]
      fieldLevel54$measureValueCompleteness[i] <- fieldLevel531$measureValueCompleteness[j]
      fieldLevel54$standardConceptRecordCompleteness[i] <- fieldLevel531$standardConceptRecordCompleteness[j]
      fieldLevel54$sourceConceptRecordCompleteness[i] <- fieldLevel531$sourceConceptRecordCompleteness[j]
      fieldLevel54$sourceValueCompleteness[i] <- fieldLevel531$sourceValueCompleteness[j]
      fieldLevel54$standardConceptFieldName[i] <- fieldLevel531$standardConceptFieldName[j]
      fieldLevel54$plausibleValueLowNotes[i] <- fieldLevel531$plausibleValueLowNotes[j]
      fieldLevel54$plausibleValueHighNotes[i] <- fieldLevel531$plausibleValueHighNotes[j]
      fieldLevel54$plausibleTemporalAfterFieldName[i] <- fieldLevel531$plausibleTemporalAfterFieldName[j]
      fieldLevel54$plausibleDuringLife[i] <- fieldLevel531$plausibleDuringLife[j]
      fieldLevel54$runForCohort[i] <- fieldLevel531$runForCohort[j]
      fieldLevel54$isRequiredThreshold[i] <- fieldLevel531$isRequiredThreshold[j]
      fieldLevel54$cdmDatatypeThreshold[i] <- fieldLevel531$cdmDatatypeThreshold[j]
      fieldLevel54$isPrimaryKey[i] <- fieldLevel531$isPrimaryKey[j]
      fieldLevel54$isForeignKey[i] <- fieldLevel531$isForeignKey[j]
      fieldLevel54$fkTableName[i] <- fieldLevel531$fkTableName[j]
      fieldLevel54$fkDomainThreshold[i] <- fieldLevel531$fkDomainThreshold[j]
      fieldLevel54$fkClassThreshold[i] <- fieldLevel531$fkClassThreshold[j]
      fieldLevel54$isStandardValidConceptThreshold[i] <- fieldLevel531$isStandardValidConceptThreshold[j]
      fieldLevel54$measureValueCompletenessThreshold[i] <- fieldLevel531$measureValueCompletenessThreshold[j]
      fieldLevel54$standardConceptRecordCompletenessThreshold[i] <- fieldLevel531$standardConceptRecordCompletenessThreshold[j]
      fieldLevel54$sourceConceptRecordCompletenessThreshold[i] <- fieldLevel531$sourceConceptRecordCompletenessThreshold[j]
      fieldLevel54$sourceValueCompletenessThreshold[i] <- fieldLevel531$sourceValueCompletenessThreshold[j]
      fieldLevel54$plausibleValueLow[i] <- fieldLevel531$plausibleValueLow[j]
      fieldLevel54$plausibleValueHigh[i] <- fieldLevel531$plausibleValueHigh[j]
      fieldLevel54$plausibleTemporalAfter[i] <- fieldLevel531$plausibleTemporalAfter[j]
      fieldLevel54$plausibleTemporalAfterThreshold[i] <- fieldLevel531$plausibleTemporalAfterThreshold[j]
      fieldLevel54$plausibleDuringLifeThreshold[i] <- fieldLevel531$plausibleDuringLifeThreshold[j]
      fieldLevel54$isRequired[i] <- fieldLevel531$isRequired[j]
      fieldLevel54$isRequiredNotes[i] <- fieldLevel531$isRequiredNotes[j]
      fieldLevel54$cdmDatatypeNotes[i] <- fieldLevel531$cdmDatatypeNotes[j]
      fieldLevel54$isPrimaryKeyThreshold[i] <- fieldLevel531$isPrimaryKeyThreshold[j]
      fieldLevel54$isForeignKeyThreshold[i] <- fieldLevel531$isForeignKeyThreshold[j]
      fieldLevel54$fkFieldName[i] <- fieldLevel531$fkFieldName[j]
      fieldLevel54$fkDomainNotes[i] <- fieldLevel531$fkDomainNotes[j]
      fieldLevel54$fkClassNotes[i] <- fieldLevel531$fkClassNotes[j]
      fieldLevel54$isStandardValidConceptNotes[i] <- fieldLevel531$isStandardValidConceptNotes[j]
      fieldLevel54$measureValueCompletenessNotes[i] <- fieldLevel531$measureValueCompletenessNotes[j]
      fieldLevel54$standardConceptRecordCompletenessNotes[i] <- fieldLevel531$standardConceptRecordCompletenessNotes[j]
      fieldLevel54$sourceConceptRecordCompletenessNotes[i] <- fieldLevel531$sourceConceptRecordCompletenessNotes[j]
      fieldLevel54$sourceValueCompletenessNotes[i] <- fieldLevel531$sourceValueCompletenessNotes[j]
      fieldLevel54$plausibleValueLowThreshold[i] <- fieldLevel531$plausibleValueLowThreshold[j]
      fieldLevel54$plausibleValueHighThreshold[i] <- fieldLevel531$plausibleValueHighThreshold[j]
      fieldLevel54$plausibleTemporalAfterTableName[i] <- fieldLevel531$plausibleTemporalAfterTableName[j]
      fieldLevel54$plausibleTemporalAfterNotes[i] <- fieldLevel531$plausibleTemporalAfterNotes[j]
      fieldLevel54$plausibleDuringLifeNotes[i] <- fieldLevel531$plausibleDuringLifeNotes[j]
      fieldLevel54$cdmDatatype[i] <- fieldLevel531$cdmDatatype[j]
      fieldLevel54$userGuidance[i] <- fieldLevel531$userGuidance[j]
      
      break
      
    }
    
  }
  
}

# Output a 5.4 field level threshold file within the parameters setup in a 5.3 file.
write.csv(fieldLevel54, file = locationNewFieldLevel154, row.names = FALSE)
}
