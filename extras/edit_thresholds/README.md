This script can be used to edit selected thresholds in a DQD result. This of course assumes that you have run the DQD, observed it, and have a list of checks for which you would like a different threshold.

## About the thresholds
There are 20 different checks. The thresholds for these checks are recorded in one of 3 files: `Table`, `Field` or `Concept` level. This script is valid for editing the three of them simultaneously.
For more information about the checks and their thresholds, visit: https://ohdsi.github.io/DataQualityDashboard/articles/CheckTypeDescriptions.html

## About this script
In the previous files, each check can be found using a combination of the check name itself, together with information from additional columns. In summary, the checks and additional columns are the following:


| | Test      | Additional columns | 
| -- | ----------- | ----------- | 
|  | __TABLE LEVEL__ |  |  
| 1 | measurePersonCompleteness      |   cdmTableName  |  
|  | __FIELD LEVEL__ |  |  |
| 2| cdmField _[not tested]_  | cdmTableName, cdmFieldName     
| 3| isRequired   | cdmTableName, cdmFieldName        | 
| 4| cdmDatatype   | cdmTableName, cdmFieldName        |
| 5| isPrimaryKey   | cdmTableName, cdmFieldName        | 
| 6| isForeignKey   | cdmTableName, cdmFieldName, fkTableName        | 
| 7| fkDomain   | cdmTableName, cdmFieldName, fkDomain        | 
| 8| fkClass   | cdmTableName, cdmFieldName, fkClass        | 
| 9| isStandardValidConcept   | cdmTableName, cdmFieldName        | 
| 10| measureValueCompleteness   | cdmTableName, cdmFieldName        | 
| 11| standardConceptRecordCompleteness   | cdmTableName, cdmFieldName        | 
| 12| sourceConceptRecordCompleteness   | cdmTableName, cdmFieldName        | 
| 13| sourceValueCompleteness   | cdmTableName, cdmFieldName        | 
| 14| plausibleValueLow   | cdmTableName, cdmFieldName      | 
| 15| plausibleValueHigh   | cdmTableName, cdmFieldName     | 
| 16| plausibleTemporalAfter   | cdmTableName, cdmFieldName  | 
| 17| plausibleDuringLife   | cdmTableName, cdmFieldName        | 
|  | __CONCEPT LEVEL__ |  |  
| 18| plausibleValueLow   | cdmTableName, cdmFieldName, conceptId, unitConceptId  | 
| 19| plausibleValueHigh   | cdmTableName, cdmFieldName, conceptId, unitConceptId    | 
| 20| plausibleGender   | cdmTableName, cdmFieldName, conceptId    | 


## How to run?

**1.** Define the checks for which you want to edit the thresholds in a .csv file, including all the 'additional columns', like this:

| Level | checkName      | cdmTableName | cdmFieldName | fkTableName	|fkDomain|conceptId | unitConceptId| Threshold | Notes |
| ----| ---- | ----- | ----- |----- | ----- |----- | ----- |----- | ----- |
| Field   | isRequired | MEASUREMENT  | person_id                | | |                          ||10| "one note" |
|Field    | plausibleValueLow  | PERSON  | year_of_birth         | | |                   ||100 | "another note" |
|Field    |	isForeignKey|	MEASUREMENT|	person_id	       | PERSON  | |                   ||1 | |
|Field 	  |fkDomain |	PERSON |	race_concept_id		       | | Race    |                   ||49 | "and yet another one" |
|Concept	|plausibleValueLow |	MEASUREMENT |	MEASUREMENT_CONCEPT_ID		| ||2212333  |8554 |56 | "note in another table" |

**2.** Run `edit_thresholds.R`. Make sure to have the correct file names.


