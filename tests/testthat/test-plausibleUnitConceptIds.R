library(testthat)

plausibleUnitThresholdFiles <- list.files(
  system.file("csv", package = "DataQualityDashboard"),
  pattern = "^OMOP_CDM(v5\\.[2-5])?_Concept_Level\\.csv$"
)

runNeutrophilUnitCheck <- function(thresholdFile, measurementConceptIds, unitConceptIds) {
  conceptChecks <- .readThresholdFile("default", thresholdFile)
  check <- conceptChecks[
    conceptChecks$cdmTableName == "MEASUREMENT" &
      conceptChecks$cdmFieldName == "MEASUREMENT_CONCEPT_ID" &
      conceptChecks$conceptId == 3017732,
  ]
  expect_equal(nrow(check), 1, info = thresholdFile)

  databaseFile <- tempfile(fileext = ".sqlite")
  on.exit(unlink(databaseFile))
  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = "sqlite",
    server = databaseFile
  )
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit({
    DatabaseConnector::disconnect(connection)
    unlink(databaseFile)
  })
  DatabaseConnector::executeSql(connection, "
    CREATE TABLE measurement (
      measurement_concept_id INTEGER,
      unit_concept_id INTEGER
    );
  ")
  if (length(measurementConceptIds) > 0) {
    values <- sprintf(
      "(%i, %s)",
      measurementConceptIds,
      ifelse(is.na(unitConceptIds), "NULL", unitConceptIds)
    )
    DatabaseConnector::executeSql(
      connection,
      paste0("INSERT INTO measurement VALUES ", paste(values, collapse = ", "), ";")
    )
  }

  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "concept_plausible_unit_concept_ids.sql",
    packageName = "DataQualityDashboard",
    dbms = "sqlite",
    warnOnMissingParameters = FALSE,
    cdmDatabaseSchema = "main",
    cdmTableName = check$cdmTableName,
    cdmFieldName = check$cdmFieldName,
    conceptId = check$conceptId,
    plausibleUnitConceptIds = check$plausibleUnitConceptIds,
    cohort = FALSE
  )
  DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE)
}

test_that("blood neutrophil counts accept /uL and reject unrelated units (#698)", {
  skip_if_not_installed("RSQLite")
  expect_gt(length(plausibleUnitThresholdFiles), 0)
  for (thresholdFile in plausibleUnitThresholdFiles) {
    result <- runNeutrophilUnitCheck(thresholdFile, 3017732L, 8647L)
    expect_equal(result$numViolatedRows, 0, info = thresholdFile)
    expect_equal(result$numDenominatorRows, 1, info = thresholdFile)
    expect_equal(result$pctViolatedRows, 0, info = thresholdFile)

    result <- runNeutrophilUnitCheck(
      thresholdFile,
      rep(3017732L, 4),
      c(8848L, 8961L, 9444L, 8554L)
    )
    expect_equal(result$numViolatedRows, 1, info = thresholdFile)
    expect_equal(result$numDenominatorRows, 4, info = thresholdFile)
    expect_equal(result$pctViolatedRows, 1 / 4, info = thresholdFile)
  }
})

test_that("neutrophil unit checks preserve zero and NULL denominator behavior", {
  skip_if_not_installed("RSQLite")
  expect_gt(length(plausibleUnitThresholdFiles), 0)
  for (thresholdFile in plausibleUnitThresholdFiles) {
    # A different measurement concept must not affect either count.
    result <- runNeutrophilUnitCheck(
      thresholdFile,
      c(3017732L, 3000000L),
      c(0L, 8554L)
    )
    expect_equal(result$numViolatedRows, 0, info = thresholdFile)
    expect_equal(result$numDenominatorRows, 0, info = thresholdFile)
    expect_equal(result$pctViolatedRows, 0, info = thresholdFile)

    result <- runNeutrophilUnitCheck(
      thresholdFile,
      c(3017732L, 3000000L),
      c(NA_integer_, 8554L)
    )
    expect_equal(result$numViolatedRows, 0, info = thresholdFile)
    expect_equal(result$numDenominatorRows, 1, info = thresholdFile)
    expect_equal(result$pctViolatedRows, 0, info = thresholdFile)
  }
})

test_that("neutrophil unit checks return zero for an empty measurement table", {
  skip_if_not_installed("RSQLite")
  expect_gt(length(plausibleUnitThresholdFiles), 0)
  for (thresholdFile in plausibleUnitThresholdFiles) {
    result <- runNeutrophilUnitCheck(thresholdFile, integer(), integer())
    expect_equal(result$numViolatedRows, 0, info = thresholdFile)
    expect_equal(result$numDenominatorRows, 0, info = thresholdFile)
    expect_equal(result$pctViolatedRows, 0, info = thresholdFile)
  }
})
