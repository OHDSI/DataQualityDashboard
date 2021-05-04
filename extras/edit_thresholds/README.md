---
title: "README.md"
output: html_document
---


# Intro
This script can be used to edit selected thresholds in a DQD result. This of course assumes that you have run the DQD, observed it, and have a list of checks for which you would like a different threshold.

## Assumptions about the checks
There are 20 different checks. The thresholds for these checks are recorded in one of 3 files. This script is valid -for now- only for the ones defined in the file `DQD_Field_Level_v5.3.1.csv`.

In this file, each check can be found using a combination of the check name itself, together with information from additional columns. For what I gathered, the checks and additional columns are the following:



| | Test      | Additional columns | Other |
| -- | ----------- | ----------- | ----------- |
| 1 | measurePersonCompleteness      |   cdmTableName  | not present in my json! |
| 2| cdmField   | cdmTableName        | |
| 3| isRequired   | cdmTableName, cdmFieldName        | |
| 4| cdmDatatype   | cdmTableName, cdmFieldName,cdmDatatype        | |
| 5| isPrimaryKey   | cdmTableName, cdmFieldName        | |
| 6| isForeignKey   | cdmTableName, cdmFieldName, fkTableName        | |
| 7| fkDomain   | cdmTableName, cdmFieldName, fkDomain        | |
| 8| fkClass   | fkClass, cdmFieldName        | |
| 9| isStandardValidConcept   | cdmTableName, cdmFieldName        | |
| 10| measureValueCompleteness   | cdmTableName, cdmFieldName        | |
| 11| standardConceptRecordCompleteness   | cdmTableName, cdmFieldName        | |
| 12| sourceConceptRecordCompleteness   | cdmTableName, cdmFieldName        | |
| 13| sourceValueCompleteness   | cdmTableName, cdmFieldName        | |
| 14| plausibleValueLow   | cdmTableName, cdmFieldName, plausibleValueLow        | Level: field check|
| 15| plausibleValueHigh   | cdmTableName, cdmFieldName, plausibleValueHigh        |Level: field check |
| 16| plausibleTemporalAfter   | cdmTableName, cdmFieldName, plausibleTemporalAfterFieldName, plausibleTemporalAfterTableName        | |
| 17| plausibleDuringLife   | cdmTableName, cdmFieldName        | |
| 18| plausibleValueLow   | cdmTableName, cdmFieldName, plausibleValueLow        | Level: concept check|
| 19| plausibleValueHigh   | cdmTableName, cdmFieldName, plausibleValueHigh        |Level: concept check |
| 20| plausibleGender   | cdmTableName, cdmFieldName, plausibleGender        | |

For more information, visit: https://ohdsi.github.io/DataQualityDashboard/articles/CheckTypeDescriptions.html


## How to run?

1. Run the `pivotLongerTable.R`, to convert the threshold-defining file into a longer version of it. It will be saved in ??
**TO DO: missing checks might be in another 'level'**

** what's the use of fkFieldName?**

2. Edit the thresholds. How?
  2a. You can open `file.csv` in Excel, and find and edit the thresholds yourself manually.
  2b. You could as well create a csv file of this form _[include table]_,
  
  | | Test      | cdmTableName | newThreshold |
  | 1 | measurePersonCompleteness | xxx  | 100 |
  | 2| measurePersonCompleteness  | yyy  | 25  |
  
  with all additional columns necessary included. Then, run a small script like this: _[add script]_
   
   ```{r}
   read_file <- 111
   read_other_file <- 222
   for(row in read_file){
        a = "do something!"
   }
   save <- ":)"
   
   ```
  
3. Run the `pivotWiderTable.R`, to convert the temporary table into its original form, that will be used for the next run or visualization of the DQD results.
**needs to be done, and then check the pivot_longer is correct**.

