% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/execution.R
\name{executeDqChecks}
\alias{executeDqChecks}
\title{Execute DQ checks}
\usage{
executeDqChecks(
  connectionDetails,
  cdmDatabaseSchema,
  resultsDatabaseSchema,
  vocabDatabaseSchema = cdmDatabaseSchema,
  cdmSourceName,
  numThreads = 1,
  sqlOnly = FALSE,
  outputFolder = "output",
  outputFile = "",
  verboseMode = FALSE,
  writeToTable = TRUE,
  writeTableName = "dqdashboard_results",
  checkLevels = c("TABLE", "FIELD", "CONCEPT"),
  checkNames = c(),
  cohortDefinitionId = c(),
  cohortDatabaseSchema = resultsDatabaseSchema,
  tablesToExclude = c(),
  cdmVersion = "5.3.1",
  tableCheckThresholdLoc = "default",
  fieldCheckThresholdLoc = "default",
  conceptCheckThresholdLoc = "default"
)
}
\arguments{
\item{connectionDetails}{A connectionDetails object for connecting to the CDM database}

\item{cdmDatabaseSchema}{The fully qualified database name of the CDM schema}

\item{resultsDatabaseSchema}{The fully qualified database name of the results schema}

\item{vocabDatabaseSchema}{The fully qualified database name of the vocabulary schema (default is to set it as the cdmDatabaseSchema)}

\item{cdmSourceName}{The name of the CDM data source}

\item{numThreads}{The number of concurrent threads to use to execute the queries}

\item{sqlOnly}{Should the SQLs be executed (FALSE) or just returned (TRUE)?}

\item{outputFolder}{The folder to output logs and SQL files to}

\item{outputFile}{(OPTIONAL) File to write results JSON object}

\item{verboseMode}{Boolean to determine if the console will show all execution steps. Default = FALSE}

\item{writeToTable}{Boolean to indicate if the check results will be written to the dqdashboard_results table
in the resultsDatabaseSchema. Default is TRUE.}

\item{checkLevels}{Choose which DQ check levels to execute. Default is all 3 (TABLE, FIELD, CONCEPT)}

\item{checkNames}{(OPTIONAL) Choose which check names to execute. Names can be found in inst/csv/OMOP_CDM_v[cdmVersion]_Check_Desciptions.csv}

\item{cohortDefinitionId}{The cohort definition id for the cohort you wish to run the DQD on. The package assumes a standard OHDSI cohort table called 'Cohort' 
with the fields cohort_definition_id and subject_id.}

\item{cohortDatabaseSchema}{The schema where the cohort table is located.}

\item{tablesToExclude}{(OPTIONAL) Choose which CDM tables to exclude from the execution.}

\item{cdmVersion}{The CDM version to target for the data source. By default, 5.3.1 is used.}

\item{tableCheckThresholdLoc}{The location of the threshold file for evaluating the table checks. If not specified the default thresholds will be applied.}

\item{fieldCheckThresholdLoc}{The location of the threshold file for evaluating the field checks. If not specified the default thresholds will be applied.}

\item{conceptCheckThresholdLoc}{The location of the threshold file for evaluating the concept checks. If not specified the default thresholds will be applied.}
}
\value{
If sqlOnly = FALSE, a list object of results
}
\description{
Execute DQ checks
}
