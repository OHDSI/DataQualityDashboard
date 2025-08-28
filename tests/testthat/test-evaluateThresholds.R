library(testthat)

test_that("evaluateThresholds handles missing table/field errors correctly for cdmField/cdmTable", {
  # Create empty objects so thresholdFieldExists will be FALSE
  tableChecks <- data.frame()
  fieldChecks <- data.frame()
  conceptChecks <- data.frame()

  # Simulate a check result for cdmField with a missing table error
  checkResults <- data.frame(
    checkName = "cdmField",
    cdmTableName = "FOO",
    cdmFieldName = "bar",
    checkLevel = "FIELD",
    error = "relation \"foo\" does not exist",
    failed = 0,
    isError = 0,
    numViolatedRows = 0,
    pctViolatedRows = 0,
    stringsAsFactors = FALSE
  )

  # Call the evaluateThresholds function
  result <- DataQualityDashboard:::.evaluateThresholds(checkResults, tableChecks, fieldChecks, conceptChecks)
  expect_equal(result$failed, 1)
  expect_equal(result$isError, 0)

  # Simulate a check result for cdmTable with a missing table error
  checkResults <- data.frame(
    checkName = "cdmTable",
    cdmTableName = "FOO",
    cdmFieldName = NA,
    checkLevel = "TABLE",
    error = "relation \"foo\" does not exist",
    failed = 0,
    isError = 0,
    numViolatedRows = 0,
    pctViolatedRows = 0,
    stringsAsFactors = FALSE
  )

  result <- DataQualityDashboard:::.evaluateThresholds(checkResults, tableChecks, fieldChecks, conceptChecks)
  expect_equal(result$failed, 1)
  expect_equal(result$isError, 0)
})

test_that("evaluateThresholds handles missing table/field errors correctly for other checks", {
  # Create empty objects so thresholdFieldExists will be FALSE
  tableChecks <- data.frame()
  fieldChecks <- data.frame()
  conceptChecks <- data.frame()

  # Simulate a check result for measurePersonCompleteness with a missing table error
  checkResults <- data.frame(
    checkName = "measurePersonCompleteness",
    cdmTableName = "FOO",
    cdmFieldName = NA,
    checkLevel = "TABLE",
    error = "relation \"foo\" does not exist",
    failed = 0,
    isError = 0,
    numViolatedRows = 0,
    pctViolatedRows = 0,
    stringsAsFactors = FALSE
  )

  result <- DataQualityDashboard:::.evaluateThresholds(checkResults, tableChecks, fieldChecks, conceptChecks)
  expect_equal(result$isError, 1)
  expect_equal(result$failed, 0)

  # Simulate a check result for measureValueCompleteness with a missing field error
  checkResults <- data.frame(
    checkName = "measureValueCompleteness",
    cdmTableName = "OBSERVATION",
    cdmFieldName = "bar",
    checkLevel = "FIELD",
    error = "column \"bar\" does not exist",
    failed = 0,
    isError = 0,
    numViolatedRows = 0,
    pctViolatedRows = 0,
    stringsAsFactors = FALSE
  )

  result <- DataQualityDashboard:::.evaluateThresholds(checkResults, tableChecks, fieldChecks, conceptChecks)
  expect_equal(result$isError, 1)
  expect_equal(result$failed, 0)
})

test_that("evaluateThresholds handles non-missing table/field errors correctly", {
  # Create empty objects so thresholdFieldExists will be FALSE
  tableChecks <- data.frame()
  fieldChecks <- data.frame()
  conceptChecks <- data.frame()

  # Simulate a check result with a general SQL error (not missing table/field)
  checkResults <- data.frame(
    checkName = "cdmTable",
    cdmTableName = "PERSON",
    cdmFieldName = NA,
    checkLevel = "TABLE",
    error = "syntax error at or near \"SELECT\"",
    failed = 0,
    isError = 0,
    numViolatedRows = 0,
    pctViolatedRows = 0,
    stringsAsFactors = FALSE
  )

  result <- DataQualityDashboard:::.evaluateThresholds(checkResults, tableChecks, fieldChecks, conceptChecks)
  expect_equal(result$isError, 1)
  expect_equal(result$failed, 0)
})
