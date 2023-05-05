DataQualityDashboard 2.2.0
==========================
This release includes:

### New features

- `cohortTableName` parameter added to `executeDqChecks`. Allows user to specify the name of the cohort table when running DQD on a cohort. Defaults to `"cohort"`


### Bugfixes

- Fixed several bugs in the default threshold files:
  - Updated plausible low value for specimen quantity from 1 to 0
  - Removed foreign key domains for episode object concept ID (multitude of plausible domains make checking this field infeasible)
  - Updated date format for hard-coded dates to `YYYYMMDD` to conform to SqlRender standard
  - Added DEATH checks to v5.2 and v5.3
  - Fixed field level checks to incorporate user-specified `vocabDatabaseSchema` and `cohortDatabaseSchema` where appropriate
- Removed `outputFile` parameter from DQD setup vignette (variable not set in script)
- Removed hidden BOM character from several threshold csv files, and updated csv read method to account for BOM character moving forward. This character caused an error on some operating systems
  
And some minor documentation updates for clarity/accuracy.

DataQualityDashboard 2.1.2
==========================

1. Fixing bug in cdmDatatype check SQL that was causing NULL values to fail the check.

DataQualityDashboard 2.1.1
==========================

1. Updating author list in DESCRIPTION.

DataQualityDashboard 2.1.0
==========================
This release includes:

### Bugfixes

  - cdmDatatype check, which checks that values in integer columns are integers, updated so that float values will now fail the check
  - Quotes removed from `offset` column name in v5.4 thresholds file so that this column is skipped by DQD in all cases (use of reserved word causes failures in some SQL dialects)
  - Broken images fixed in addNewCheck vignette

### HADES requirements

  - All snakecase variables updated to camelcase
  - Global variable binding R Check note resolved

DataQualityDashboard 2.0.0
===========================
This release includes:

### New check statuses

  - **Not Applicable** identifies checks with no data to support them
  - **Error** identifies checks that failed due to a SQL error

### New Checks

  - **measureConditionEraCompleteness** checks to make sure that every person with a Condition_Era record have a record in Condition_Occurrence as well
  - **withinVisitDates** looks at clinical facts and the visits they are associated with to make sure that the visit dates occur within one week on either side of the visit
  - **plausibleUnitConceptIds** identifies records with invalid Unit_Concept_Ids by Measurement_Concept_Id

### outputFolder input paramater

  - The `outputFolder` parameter for the `executeDqChecks` function is now REQUIRED and no longer has a default value.  **This may be a breaking change for users who have not specified this parameter in their script to run DQD.**

### Integrated testing was also added and the package was refactored on the backend

DataQualityDashboard 1.4.1
===========================
No material changes from v1.4, this adds a correct `DESCRIPTION` file 
with the correct DQD version

DataQualityDashboard 1.4
===========================
This release provides support for `CDM v5.4` and incorporates minor bug fixes 
related to incorrectly assigned checks in the control files.

DataQualityDashboard 1.3.1
===========================
This fixes a small bug and removes a duplicate record in the concept level checks 
that was throwing an error.

DataQualityDashboard 1.3
===========================
This release includes additional concept level checks to support 
the OHDSI Symposium 2020 study-a-thon and bug fixes to the `writeJSONToTable` function. 
This is the release that study-a-thon data partners should use.

DataQualityDashboard 1.2
===========================
This is a bug fix release that updates how notes are viewed in the UI and adds 
CDM table, field, and check name to the final table.

DataQualityDashboard 1.1
===========================
This release of the Data Quality Dashboard incorporates the following features:
- Addition of notes fields in the threshold files
- Addition of notes to the UI
- Functionality to run the DQD on a cohort
- Fixes the `writeToTable`, `writeJsonToTable` functions

DataQualityDashboard 1.0
===========================
This is the first release of the OHDSI Data Quality Dashboard tool.
