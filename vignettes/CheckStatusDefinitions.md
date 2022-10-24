---
title: "Check Status Descriptions"
author: "Dmitry Ilyn"
date: "2022-10-14"
header-includes:
    - \usepackage{fancyhdr}
    - \pagestyle{fancy}
    - \fancyhead{}
    - \fancyhead[CO,CE]{Data Quality Check Type Definitions}
    - \fancyfoot[CO,CE]{DataQualityDashboard Package Version 1.4.1}
    - \fancyfoot[LE,RO]{\thepage}
    - \renewcommand{\headrulewidth}{0.4pt}
    - \renewcommand{\footrulewidth}{0.4pt}
output:
  html_document:
    number_sections: yes
    toc: yes
---

<!--
%\VignetteEngine{knitr::knitr}
%\VignetteIndexEntry{Check Status Descriptions}
-->

# DQD check statuses

## Introduction
In the DataQualityDashboard v2, new check statuses were introduced: `Error` and `Not Applicable`. These were introduced to more accurately reflect the quality of data contained in a CDM instance, addressing scenarios where pass/fail is not appropriate. The new set of mutually exclusive status states are listed below in priority order:

- **Is Error:** if a SQL error occurred during execution

- **Not Applicable:** if DQ check is not applicable for reasons explained in the section below

- **Failed:** if percent violating rows is greater than the threshold

- **Passed:** if percent violating rows is smaller than the threshold


## Not Applicable

The results of a DQ check may not be applicable to a given CDM instance depending on the implementation and content of the instance. For example, the DQ check for plausible values of HbA1c lab results would pass with no violations even if there were no results for that lab test in the database. It is not uncommon to have \> 1000 DQ checks that do not apply to a given CDM instance. The results from DQ checks that are not applicable skew to overall results. Listed below are the scenarios for which a DQ check result is flagged as Not_applicable:

1.  If the cdmTable DQ check determines that a table does not exist in the database, then all DQ checks (except cdm_table) addressing that table are flagged as Not_applicable.

2.  If a table exists but is empty, then all field level and concept level checks for that table are flagged as Not_applicable, except for cdmField checks, which evaluates if the field is defined or not. A cdmField check is marked as not_applicable if the CDM table it refers to does not exist (tested by cdmTable). An empty table is detected when the measureValueCompleteness DQ check for any of the fields in the table returns a denominator count = 0 (NUM_DENOMINATOR_ROWS=0).

3.  If a field is not populated, then all field level and concept level checks except for measureValueCompleteness and isRequired are flagged as Not_applicable.

    a. A field is not populated if the measureValueCompleteness DQ check finds denominator count \> 0 and number of violated rows = denominator count (NUM_DENOMINATOR_ROWS \> 0 AND NUM_DENOMINATOR_ROWS = NUM_VIOLATED_ROWS).

    b. The measureValueCompleteness check is marked as not applicable if:

        a. The CDM table it refers to does not exist or is empty.

        b. The CDM field it refers to does not exist.

    c. The isRequired check is marked as not applicable if:

        a. The CDM table it refers to does not exist or is empty.

        b. The CDM field it refers to does not exist.

4.  Flagging a Concept_ID level DQ check as Not_applicable depends on whether the DQ check logic includes a UNIT_CONCEPT_ID. There are two scenarios for DQ checks evaluating specific Concept_ids.

    a. The DQ check does not include a UNIT_CONCEPT_ID (value is null). A DQ check is flagged as Not_applicable if there are no instances of the Concept_ID in the table/field. E.g. plausibility checks for specific conditions and gender. Both pregnancy and male do not have UNIT_CONCEPT_IDs.

    b. The DQ check includes a UNIT_CONCEPT_ID. A DQ check is flagged as Not_applicable if there are no instances of both concept and unit concept IDs in the table/field. E.g. all DQ checks referencing the concept_ID for HbA1c lab results expressed in mg/dl units will be flagged as Not_applicable if there are no instances of that concept_ID in the table/field addressed by the DQ check.

