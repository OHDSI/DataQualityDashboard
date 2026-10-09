# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DataQualityDashboard is an R package (part of OHDSI/HADES) that assesses data quality of OMOP CDM databases. It runs ~4,000 parameterized checks across three categories (Plausibility, Conformance, Completeness) and produces results viewable via a Shiny dashboard.

## Common Commands

```r
# Build and check
devtools::build()
devtools::check()
R CMD check --as-cran --no-manual .

# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-executeDqChecks.R")

# Run tests matching a pattern
testthat::test_file("tests/testthat/test-executeDqChecks.R", filter = "Execute a single DQ check")

# Lint
lintr::lint_package()

# Install local dev version
devtools::install()
```

## Architecture

### Execution Flow

```
executeDqChecks() → SQL generation (SqlRender) → DB execution (DatabaseConnector)
  → evaluateThresholds() → calculateNotApplicableStatus() → summarizeResults()
  → writeJsonResultsTo() / writeDBResultsTo()
  → viewDqDashboard() (Shiny)
```

### Check Definition System

Checks are defined in CSV files at `inst/csv/` — a table-level and field-level set per CDM version (5.3, 5.4, 5.5), plus a single concept-level file shared by all versions. Each CSV row defines a parameterized check (table-level, field-level, or concept-level). The ~24 check types correspond to SQL templates in `inst/sql/sql_server/`. `SqlRender` translates these to the target database dialect at runtime.

### Public API (6 exported functions)

- `executeDqChecks()` — main entry point; runs checks and returns/writes results
- `viewDqDashboard()` — launches Shiny app from a results JSON file
- `listDqChecks()` — list available checks without executing
- `reEvaluateThresholds()` — re-score existing results with new thresholds
- `writeJsonResultsToJson()` / `writeJsonResultsToCsv()` — output format conversion
- `convertJsonResultsFileCase()` — convert result keys between snake_case and camelCase

### Key Source Files

| File | Purpose |
|------|---------|
| `R/executeDqChecks.R` | Main orchestration logic |
| `R/evaluateThresholds.R` | Pass/fail/warning scoring |
| `R/calculateNotApplicableStatus.R` | Determines when checks don't apply |
| `R/recordResult.R` | Stores individual check results |
| `R/summarizeResults.R` | Aggregates counts/percentages |
| `R/writeJsonResultsTo.R` / `R/writeDBResultsTo.R` | Output writers |
| `inst/shinyApps/` | Dashboard Shiny app |

## Testing

Most tests use [Eunomia](https://github.com/OHDSI/Eunomia) (synthetic OMOP CDM data in-memory via DuckDB) — no external database needed. Connection setup is in `tests/testthat/setup.R`. Many tests use `withCallingHandlers(..., warning = ...)` to muffle expected check-name warnings.

Tests also exist to test the package on other DBMS; these connect to remotely hosted warehouses using creds stored in .Renviron.

Snapshot tests live in `tests/testthat/_snaps/`.

## CDM Version Support

Checks are versioned: `inst/csv/OMOP_CDMv5.3_Check_Descriptions.csv`, `5.4`, `5.5`. When adding or modifying checks, changes typically need to be applied across all relevant CDM version CSVs and their corresponding SQL templates. Concept level thresholds are shared across versions in `inst/csv/OMOP_CDM_Concept_Level.csv`.

## Linting

`.lintr` excludes `sql/`, `output/`, `docs/`, and `inst/doc/`. Run `lintr::lint_package()` before submitting PRs.
