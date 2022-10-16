library(testthat)

test_that("listDqChecks works", {
  result <- DataQualityDashboard:::is_installed("SqlRender")
  expect_true(result)
  expect_null(DataQualityDashboard:::ensure_installed("SqlRender"))
})