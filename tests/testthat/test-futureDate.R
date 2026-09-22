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
