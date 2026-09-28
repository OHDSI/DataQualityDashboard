# Tests for the deterministic futureDate used by plausibleValueHigh checks (#277)

test_that("@futureDate placeholder resolves to a deterministic date literal", {
  expect_equal(
    .resolveFutureDatePlaceholder("DATEADD(dd,1,@futureDate)", "2024-06-30"),
    "DATEADD(dd,1,'2024-06-30')"
  )
  expect_equal(
    .resolveFutureDatePlaceholder("YEAR(@futureDate)+1", "2024-06-30"),
    "YEAR('2024-06-30')+1"
  )
  # thresholds without the placeholder are left untouched
  expect_equal(
    .resolveFutureDatePlaceholder("0", "2024-06-30"),
    "0"
  )
})

test_that("@futureDate placeholder keeps legacy GETDATE() behavior when futureDate is NULL (sqlOnly mode)", {
  expect_equal(
    .resolveFutureDatePlaceholder("DATEADD(dd,1,@futureDate)", NULL),
    "DATEADD(dd,1,CAST(GETDATE() AS DATE))"
  )
})

test_that("field-level control files no longer reference GETDATE() in plausibleValueHigh thresholds (#277)", {
  for (cdmVersion in c("5.2", "5.3", "5.4")) {
    csvFile <- system.file(
      "csv",
      sprintf("OMOP_CDMv%s_Field_Level.csv", cdmVersion),
      package = "DataQualityDashboard"
    )
    fieldChecks <- readr::read_csv(csvFile, show_col_types = FALSE)
    expect_false(
      any(grepl("getdate", fieldChecks$plausibleValueHigh, ignore.case = TRUE), na.rm = TRUE),
      info = sprintf("OMOP_CDMv%s_Field_Level.csv still references GETDATE()", cdmVersion)
    )
    # every remaining threshold that constrains "future" dates goes through @futureDate
    futureThresholds <- fieldChecks$plausibleValueHigh[
      grepl("futuredate", fieldChecks$plausibleValueHigh, ignore.case = TRUE)
    ]
    expect_true(length(futureThresholds) > 0)
  }
})

test_that("future-date checks skipped for missing source_release_date are marked not-applicable (#277)", {
  skipped <- data.frame(
    checkName = "plausibleValueHigh",
    cdmTableName = "OBSERVATION",
    isError = 0,
    tableIsMissing = FALSE,
    fieldIsMissing = FALSE,
    tableIsEmpty = FALSE,
    fieldIsEmpty = FALSE,
    conceptIsMissing = FALSE,
    conceptAndUnitAreMissing = FALSE,
    futureDateSkipped = TRUE
  )
  expect_equal(DataQualityDashboard:::.applyNotApplicable(skipped), 1)

  # rows that were actually executed are unaffected by the new rule
  executed <- skipped
  executed$futureDateSkipped <- FALSE
  expect_equal(DataQualityDashboard:::.applyNotApplicable(executed), 0)

  # the rule is also safe on result rows predating the futureDateSkipped column
  legacy <- executed[, names(executed) != "futureDateSkipped"]
  expect_equal(DataQualityDashboard:::.applyNotApplicable(legacy), 0)
})

test_that(".recordFutureDateSkipped flags the result row and records no SQL", {
  check <- c(cdmTableName = "OBSERVATION", cdmFieldName = "observation_date", conceptId = "", unitConceptId = "")
  checkDescription <- list(
    checkName = "plausibleValueHigh",
    checkLevel = "FIELD",
    checkDescription = "test",
    sqlFile = "plausible_value_high.sql",
    kahnCategory = "plausibility",
    kahnSubcategory = "atemporal",
    kahnContext = "verification"
  )
  result <- DataQualityDashboard:::.recordFutureDateSkipped(check = check, checkDescription = checkDescription)
  expect_true(result$futureDateSkipped)
  expect_true(is.na(result$queryText))
  expect_false(is.na(result$warning))
})
