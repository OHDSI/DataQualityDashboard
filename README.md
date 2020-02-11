DataQualityDashboard
====================

[![Build Status](https://travis-ci.org/OHDSI/DataQualityDashboard.svg?branch=master)](https://travis-ci.org/OHDSI/DataQualityDashboard)
[![codecov.io](https://codecov.io/github/OHDSI/DataQualityDashboard/coverage.svg?branch=master)](https://codecov.io/github/OHDSI/DataQualityDashboard?branch=master)


The DataQualityDashboard is a tool to help improve data quality standards in observational data science.

<img src="https://github.com/OHDSI/DataQualityDashboard/raw/master/extras/dqDashboardScreenshot.png"/>

Introduction
============
An R package for characterizing the data quality of a person-level data source that has been converted into the OMOP CDM 5.3.1 format.

Features
========
- Utilizes configurable data check thresholds
- Analyzes data in the OMOP Common Data Model format for all data checks
- Produces a set of data check results with supplemental investigation assets.


Technology
==========
DataQualityDashboard is an R package 

System Requirements
===================
Requires R (version 3.2.2 or higher). Requires [DatabaseConnector](https://github.com/OHDSI/DatabaseConnector) and [SqlRender](https://github.com/OHDSI/SqlRender).

R Installation
===============

```r
install.packages("devtools")
devtools::install_github("OHDSI/DataQualityDashboard")
```

Executing Data Quality Checks
==============================
  ```r

# fill out the connection details -----------------------------------------------------------------------
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "", 
                                                                user = "", 
                                                                password = "", 
                                                                server = "", 
                                                                port = "", 
                                                                extraSettings = "")

cdmDatabaseSchema <- "yourCdmSchema" # the fully qualified database schema name of the CDM
resultsDatabaseSchema <- "yourResultsSchema" # the fully qualified database schema name of the results schema (that you can write to)
cdmSourceName <- "Your CDM Source" # a human readable name for your CDM source

# determine how many threads (concurrent SQL sessions) to use ----------------------------------------
numThreads <- 1 # on Redshift, 3 seems to work well

# specify if you want to execute the queries or inspect them ------------------------------------------
sqlOnly <- FALSE # set to TRUE if you just want to get the SQL scripts and not actually run the queries

# where should the logs go? -------------------------------------------------------------------------
outputFolder <- "output"

# logging type -------------------------------------------------------------------------------------
verboseMode <- FALSE # set to TRUE if you want to see activity written to the console

# write results to table? ------------------------------------------------------------------------------
writeToTable <- TRUE # set to FALSE if you want to skip writing to a SQL table in the results schema

# if writing to table and using Redshift, bulk loading can be initialized -------------------------------

# Sys.setenv("AWS_ACCESS_KEY_ID" = "",
#            "AWS_SECRET_ACCESS_KEY" = "",
#            "AWS_DEFAULT_REGION" = "",
#            "AWS_BUCKET_NAME" = "",
#            "AWS_OBJECT_KEY" = "",
#            "AWS_SSE_TYPE" = "AES256",
#            "USE_MPP_BULK_LOAD" = TRUE)

# which DQ check levels to run -------------------------------------------------------------------
checkLevels <- c("TABLE", "FIELD", "CONCEPT")

# which DQ checks to run? ------------------------------------

checkNames <- c() # Names can be found in inst/csv/OMOP_CDM_v5.3.1_Check_Desciptions.csv

# run the job --------------------------------------------------------------------------------------
DataQualityDashboard::executeDqChecks(connectionDetails = connectionDetails, 
                                      cdmDatabaseSchema = cdmDatabaseSchema, 
                                      resultsDatabaseSchema = resultsDatabaseSchema,
                                      cdmSourceName = cdmSourceName, 
                                      numThreads = numThreads,
                                      sqlOnly = sqlOnly, 
                                      outputFolder = outputFolder, 
                                      verboseMode = verboseMode,
                                      writeToTable = writeToTable,
                                      checkLevels = checkLevels,
                                      checkNames = checkNames)

# inspect logs ----------------------------------------------------------------------------
ParallelLogger::launchLogViewer(logFileName = file.path(outputFolder, cdmSourceName, 
                                                        sprintf("log_DqDashboard_%s.txt", cdmSourceName)))

# (OPTIONAL) if you want to write the JSON file to the results table separately -----------------------------
jsonFilePath <- ""
DataQualityDashboard::writeJsonResultsToTable(connectionDetails = connectionDetails, 
                                              resultsDatabaseSchema = resultsDatabaseSchema, 
                                              jsonFilePath = jsonFilePath)
                                              

```

Viewing Results
================

**Launching Dashboard as Shiny App**
```r
DataQualityDashboard::viewDqDashboard(jsonPath = file.path(getwd(), outputFolder, cdmSourceName, sprintf("results_%s.json", cdmSourceName)))
```

**Launching on a web server**

If you have npm installed:

1. Install http-server:

```
npm install -g http-server
```

2. Rename the json file to *results.json* and place it in inst/shinyApps/www

3. Go to inst/shinyApps/www, then run:

```
http-server
```

A results JSON file for the Synthea synthetic dataset will be shown. You can view your results by replacing the results.json file with your file (with name results.json).



View checks
===========
To see description of checks using R, execute the command bellow:
```
View(read.csv(system.file("csv","OMOP_CDMv5.3.1_Check_Descriptions.csv",package="DataQualityDashboard"),as.is=T))
```


Support
=======

* Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
* We use the <a href="https://github.com/OHDSI/DataQualityDashboard/issues">GitHub issue tracker</a> for all bugs/issues/enhancements 
 
License
=======
DataQualityDashboard is licensed under Apache License 2.0

### Development status

V1.0 ready for use. 

# Acknowledgements

This project is supported in part through the National Science Foundation grant IIS 1251151.
