DataQualityDashboard
====================

The goal of the Data Quality Dashboard (DQD) project is to design and develop an open-source tool to expose and evaluate observational data quality. 

Introduction
============

This repository forked from https://github.com/OHDSI/DataQualityDashboard. 

This package will run a series of data quality checks against an OMOP CDM instance (currently supports v5.3.1 and v5.2.2). It systematically runs the checks, evaluates the checks against some pre-specified threshold, and then communicates what was done in a transparent and easily understandable way. 

This service wraps **DataQualityDashboard** functional in Web-service that used by Perseus https://github.com/SoftwareCountry/Perseus. 

Overview
========

The quality checks were organized according to the Kahn Framework<sup id="kahn">[1](#f1)</sup> which uses a system of categories and contexts that represent strategies for assessing data quality. For an introduction to the kahn framework please click [here](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5051581/). 

Using this framework, the Data Quality Dashboard takes a systematic-based approach to running data quality checks. Instead of writing thousands of individual checks, we use “data quality check types”. These “check types” are more general, parameterized data quality checks into which OMOP tables, fields, and concepts can be substituted to represent a singular data quality idea. For example, one check type might be written as 

*The number and percent of records with a value in the **cdmFieldName** field of the **cdmTableName** table less than **plausibleValueLow**.*

This would be considered an atemporal plausibility verification check because we are looking for implausibly low values in some field based on internal knowledge. We can use this check type to substitute in values for **cdmFieldName**, **cdmTableName**, and **plausibleValueLow** to create a unique data quality check. If we apply it to PERSON.YEAR_OF_BIRTH here is how that might look: 

*The number and percent of records with a value in the **year_of_birth** field of the **PERSON** table less than **1850**.* 

And, since it is parameterized, we can similarly apply it to DRUG_EXPOSURE.days_supply: 

*The number and percent of records with a value in the **days_supply** field of the **DRUG_EXPOSURE** table less than **0**.* 

Version 1 of the tool includes 20 different check types organized into Kahn contexts and categories. Additionally, each data quality check type is considered either a table check, field check, or concept-level check. Table-level checks are those evaluating the table at a high-level without reference to individual fields, or those that span multiple event tables. These include checks making sure required tables are present or that at least some of the people in the PERSON table have records in the event tables. Field-level checks are those related to specific fields in a table. The majority of the check types in version 1 are field-level checks. These include checks evaluating primary key relationship and those investigating if the concepts in a field conform to the specified domain. Concept-level checks are related to individual concepts. These include checks looking for gender-specific concepts in persons of the wrong gender and plausible values for measurement-unit pairs. For a detailed description and definition of each check type please click [here](https://ohdsi.github.io/DataQualityDashboard/articles/CheckTypeDescriptions). 

After systematically applying the 20 check types to an OMOP CDM version approximately 3,351 individual data quality checks are resolved, run against the database, and evaluated based on a pre-specified threshold. The R package then creates a json object that is read into an RShiny application to view the results.


<img src="https://github.com/OHDSI/DataQualityDashboard/raw/master/extras/dqDashboardScreenshot.png"/>


Features
========
- Utilizes configurable data check thresholds
- Analyzes data in the OMOP Common Data Model format for all data checks
- Produces a set of data check results with supplemental investigation assets.


Technology
==========

- Java 17
- R 4.1.3

Getting Started
==========

### R server

    cd R
    docker build -t r-serve --build-arg prop='docker' .
    docker run --name r-serve -d -p 6311:6311 --network=perseus-net r-serve

### Data-quality-check service

    docker build -t data-quality-dashboard .
    docker run --name data-quality-dashboard -d -p 8001:8001 -e SPRING_PROFILES_ACTIVE='docker' --network=perseus-net data-quality-dashboard

Development
==========

### R server

    cd R
    docker build -t r-serve --build-arg prop='docker' .
    docker run --name r-serve -d -p 6311:6311 r-serve

License
=======
DataQualityDashboard is licensed under Apache License 2.0
