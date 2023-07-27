library(testthat)

test_that("listDqChecks works", {
  checks <- listDqChecks()
  expect_equal(length(checks), 4)
  expect_true(all(sapply(checks, is.data.frame)))
})
