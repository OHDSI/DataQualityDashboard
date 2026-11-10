library(testthat)

# Each test works on its own copy of the Eunomia database so that inserted
# rows do not leak into other tests that share the cached database file.
.copyEunomiaDb <- function() {
  source <- Eunomia::getDatabaseFile(
    datasetName = "GiBleed",
    cdmVersion = "5.3",
    dbms = "sqlite",
    overwrite = FALSE
  )
  target <- tempfile(fileext = ".sqlite")
  file.copy(source, target)
  target
}

.runWithinObservationPeriod <- function(connectionDetails, outputFolder, fieldCheckThresholdLoc = "default") {
  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetails,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      cdmVersion = "5.3",
      checkNames = "withinObservationPeriod",
      fieldCheckThresholdLoc = fieldCheckThresholdLoc,
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )
  results$CheckResults[
    results$CheckResults$checkName == "withinObservationPeriod" &
      results$CheckResults$cdmTableName == "CONDITION_OCCURRENCE",
  ]
}

test_that("withinObservationPeriod counts records outside every observation period and is informational by default", {
  testthat::skip_if_not_installed("Eunomia")
  dbFile <- .copyEunomiaDb()
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(c(dbFile, outputFolder), recursive = TRUE))
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sqlite", server = dbFile)

  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)

  expectedBaseline <- DatabaseConnector::querySql(connection, "
    SELECT COUNT(*) AS n
    FROM condition_occurrence co
    WHERE NOT EXISTS (
      SELECT 1 FROM observation_period op
      WHERE op.person_id = co.person_id
        AND co.condition_start_date >= op.observation_period_start_date
        AND co.condition_start_date <= op.observation_period_end_date
    );")[1, 1]

  baseline <- .runWithinObservationPeriod(connectionDetails, outputFolder)
  expect_equal(nrow(baseline), 1)
  expect_equal(baseline$numViolatedRows, expectedBaseline)
  expect_equal(baseline$isError, 0)
  # Default threshold is 100%, so the check never fails out of the box
  expect_equal(baseline$thresholdValue, 100)
  expect_equal(baseline$failed, 0)

  # Use a person with exactly one observation period, then insert one record on
  # the first day of the period (boundary: inside), one on the last day
  # (boundary: inside), and one the day before the period (outside). Dates are
  # derived in SQL so they keep the database's native date representation.
  DatabaseConnector::renderTranslateExecuteSql(connection, "
    SELECT op.person_id, op.observation_period_start_date, op.observation_period_end_date
    INTO #single_op
    FROM observation_period op
    WHERE op.person_id = (
      SELECT MIN(person_id)
      FROM (SELECT person_id FROM observation_period GROUP BY person_id HAVING COUNT(*) = 1) p
    );

    INSERT INTO condition_occurrence
      (condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_type_concept_id)
    SELECT 990001 + offset_id, person_id, 40481087, event_date, 32020
    FROM (
      SELECT 0 AS offset_id, person_id, observation_period_start_date AS event_date FROM #single_op
      UNION ALL
      SELECT 1, person_id, observation_period_end_date FROM #single_op
      UNION ALL
      SELECT 2, person_id, DATEADD(day, -1, observation_period_start_date) FROM #single_op
    ) inserts;",
    progressBar = FALSE, reportOverallTime = FALSE
  )

  withInserts <- .runWithinObservationPeriod(connectionDetails, outputFolder)
  expect_equal(withInserts$numViolatedRows, expectedBaseline + 1)
  expect_equal(withInserts$numDenominatorRows, baseline$numDenominatorRows + 3)
})

test_that("withinObservationPeriod fails when a stricter threshold is supplied", {
  testthat::skip_if_not_installed("Eunomia")
  dbFile <- .copyEunomiaDb()
  outputFolder <- tempfile("dqd_")
  thresholdFile <- tempfile(fileext = ".csv")
  on.exit(unlink(c(dbFile, outputFolder, thresholdFile), recursive = TRUE))
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sqlite", server = dbFile)

  fieldChecks <- read.csv(
    system.file("csv", "OMOP_CDMv5.3_Field_Level.csv", package = "DataQualityDashboard"),
    colClasses = "character", na.strings = ""
  )
  target <- fieldChecks$cdmTableName == "CONDITION_OCCURRENCE" & fieldChecks$cdmFieldName == "condition_start_date"
  fieldChecks$withinObservationPeriodThreshold[target] <- "0"
  write.csv(fieldChecks, thresholdFile, row.names = FALSE, na = "")

  result <- .runWithinObservationPeriod(connectionDetails, outputFolder, fieldCheckThresholdLoc = thresholdFile)
  expect_equal(result$thresholdValue, 0)
  expect_true(result$numViolatedRows > 0)
  expect_equal(result$failed, 1)
})
