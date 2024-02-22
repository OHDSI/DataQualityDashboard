DataQualityDashboard 2.6.0
==========================
This release includes: 

### New Checks
4 new data quality check types have been added in this release:

- `plausibleStartBeforeEnd`: The number and percent of records with a value in the **cdmFieldName** field of the **cdmTableName** that occurs after the date in the **plausibleStartBeforeEndFieldName**.
- `plausibleAfterBirth`: The number and percent of records with a date value in the **cdmFieldName** field of the **cdmTableName** table that occurs prior to birth.
- `plausibleBeforeDeath`: The number and percent of records with a date value in the **cdmFieldName** field of the **cdmTableName** table that occurs after death.
- `plausibleGenderUseDescendants`: For descendants of CONCEPT_ID **conceptId** (**conceptName**), the number and percent of records associated with patients with an implausible gender (correct gender = **plausibleGenderUseDescendants**).

The 3 temporal plausibilty checks are intended to **replace** `plausibleTemporalAfter` and `plausibleDuringLife`, for a more comprehensive and clear approach to various temporality scenarios.  `plausibleGenderUseDescendants` is intended to **replace** `plausibleGender`, to enhance readability of the DQD results and improve performance.  The replaced checks are still available and enabled by default in DQD; however, in a future major release, these checks will be deprecated.  Please plan accordingly.

For more information on the new checks, please check the [Check Type Definitions](https://ohdsi.github.io/DataQualityDashboard/articles/CheckTypeDescriptions.html) documentation page.  If you'd like to disable the deprecated checks, please see the suggested check exclusion workflow in our Getting Started code [here](https://ohdsi.github.io/DataQualityDashboard/articles/DataQualityDashboard.html).

### New Documentation
We have begun an initiative to add more comprehensive user documentation at the data quality check level.  A dedicated documentation page is being created for each check type.  Each check's page will include detailed information about how its result is generated and what to do if it fails.  Guidance is provided for both ETL developers and data users.

9 pages have been added so far, and the rest will come in a future release.  Check them out [here](https://ohdsi.github.io/DataQualityDashboard/articles/checkIndex.html) and please reach out with feedback as we continue improving our documentation!

DataQualityDashboard 2.5.0
==========================
This release includes: 

### New Feature
A new function `writeDBResultsToJson` which can be used to write DQD results previously written to a database table (by setting `writeToTable` = TRUE in `executeDqChecks` or by using the `writeJsonResultsToTable` function) into a JSON file in the standard DQD JSON format.

### Bugfixes
- DQD previously threw an error if the CDM_SOURCE table contained more than 1 row. It has now been updated to select a random row from CDM_SOURCE to use for its metadata and warn the user upon doing this. Whether or not CDM_SOURCE *should* ever contain more than 1 row is still an unresolved discussion in the community. Either way, DQD should be allowed to run if the table has been improperly populated - and perhaps check(s) should be added for its proper use once a convention is finalized
- Fixed additional field level checks (fkDomain, fkClass, plausibleTemporalAfter) to incorporate user-specified `vocabDatabaseSchema` where appropriate
- Additional minor bugfixes & refactors

DataQualityDashboard 2.4.1
==========================
This release includes: 

- Minor documentation updates
- A patch for an issue in one of DQD's transitive dependencies, `vroom`
- Test suite upgrades to run remote DB tests against OMOP v5.4, and to add Redshift to remote DB tests

DataQualityDashboard 2.4.0
==========================
This release includes:

### Threshold file updates
**The following changes involve updates to the default data quality check threshold files. If you are currently using an older version of DQD and update to v2.4.0, you may see changes in your DQD results. The failure threshold changes are fixes to incorrect thresholds in the v5.4 files and thus should result in more accurate, easier to interpret results. The unit concept ID changes ensure that long-invalid concepts will no longer be accepted as plausible measurement units.**

- The incorrect failure thresholds for `measurePersonCompleteness` and `measureValueCompleteness` were fixed in the v5.4 table & field level threshold files.  This issue has existed since v5.4 support was initially added in March 2022
  - Many `measurePersonCompleteness` checks had a threshold of 0 when it should have been 95 or 100
  - Many `measureValueCompleteness` checks had a threshold of 100 when it should have been 0, and many had no threshold (defaulting to 0) when it should have been 100
  - The thresholds have now been updated to match expectations for required/non-required tables/fields
- In the v5.2, v5.3, and v5.4 table level threshold files, `measurePersonCompleteness` for the DEATH table has been toggled to `Yes`, with a threshold of 100
- In the v5.2, v5.3, and v5.4 concept level threshold files, all references to unit concept 9117 in `plausibleUnitConceptIds` have been updated to 720870.  Concept 9117 became non-standard and was replaced with concept 720870, on 28-Mar-2022
- In the v5.2, v5.3, and v5.4 concept level threshold files, all references to unit concepts 9258 and 9259 in `plausibleUnitConceptIds` have been removed. These concepts were deprecated on 05-May-2022

### Bugfix
- Call to new function `convertJsonResultsFileCase` in Shiny app was appended with `DataQualityDashboard::`. This prevents potential issues related to package loading and function naming conflicts

Some minor refactoring of testthat files and package build configuration and some minor documentation updates were also added in this release.

DataQualityDashboard 2.3.0
==========================
This release includes:

### New features

- *New SQL-only Mode:* Setting `sqlOnly` and `sqlOnlyIncrementalInsert` to TRUE in `executeDqChecks` will return (but not run) a set of SQL queries that, when executed, will calculate the results of the DQ checks and insert them into a database table. Additionally, `sqlOnlyUnionCount` can be used to specify a number of SQL queries to union for each check type, allowing for parallel execution of these queries and potentially large performance gains. See the [SqlOnly vignette](https://ohdsi.github.io/DataQualityDashboard/articles/SqlOnly.html) for details
- *Results File Case Converter:* The new function `convertJsonResultsFileCase` can be used to convert the keys in a DQD results JSON file between snakecase and camelcase. This allows reading of v2.1.0+ JSON files in older DQD versions, and other conversions which may be necessary for secondary use of the DQD results file. See [function documentation](https://ohdsi.github.io/DataQualityDashboard/reference/convertJsonResultsFileCase.html) for details

### Bugfixes

- In the v2.1.0 release, all DQD variables were converted from snakecase to camelcase, including those in the results JSON file. This resulted in errors for users trying to view results files generated by older DQD versions in DQD v2.1.0+. This issue has now been fixed. `viewDqDashboard` will now automatically convert the case of pre-v2.1.0 results files to camelcase so that older results files may be viewed in v2.3.0+


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

### outputFolder input parameter

  - The `outputFolder` parameter for the `executeDqChecks` function is now REQUIRED and no longer has a default value.  **This may be a breaking change for users who have not specified this parameter in their script to run DQD.**

### Removal of measurement plausibility checks

  - Most plausibleValueLow and plausibleValueHigh measurement values were removed from the concept check threshold files, due to feedback from the community that many of these ranges included plausible values and as such were causing unexpected check failures. An initiative is planned to reinterrogate these ranges and add them back once the team has higher confidence that they will only flag legitimately implausible values 

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
