library(testthat)

test_that("listDqChecks works", {
  checks <- listDqChecks()
  expect_equal(length(checks), 4)
  expect_true(all(sapply(checks, is.data.frame)))
})

test_that("listDqChecks works for all supported CDM versions", {
  for (cdmVersion in c("5.2", "5.3", "5.4", "5.5")) {
    checks <- listDqChecks(cdmVersion = cdmVersion)
    expect_equal(length(checks), 4)
    expect_true(all(sapply(checks, is.data.frame)))
    expect_true(all(sapply(checks, nrow) > 0))
  }
})

test_that("v5.5 threshold files contain the tables and fields added in CDM v5.5", {
  checks <- listDqChecks(cdmVersion = "5.5")

  newTables <- c("PACK_CONTENT", "CONCEPT_METADATA", "CONCEPT_RELATIONSHIP_METADATA")
  expect_true(all(newTables %in% checks$tableChecks$cdmTableName))
  expect_true(all(newTables %in% checks$fieldChecks$cdmTableName))

  newFields <- data.frame(
    cdmTableName = c("MEASUREMENT", "OBSERVATION", "OBSERVATION", "OBSERVATION", "SPECIMEN", "SPECIMEN", "CDM_SOURCE"),
    cdmFieldName = c(
      "value_as_source_concept_id", "value_as_source_concept_id", "unit_source_concept_id",
      "value_as_date", "visit_occurrence_id", "visit_detail_id", "cdm_release_identifier"
    )
  )
  expect_equal(nrow(merge(newFields, checks$fieldChecks)), nrow(newFields))

  # v5.5 covers everything v5.4 does
  v54 <- listDqChecks(cdmVersion = "5.4")
  key <- function(x) paste(x$cdmTableName, x$cdmFieldName)
  expect_true(all(key(v54$fieldChecks) %in% key(checks$fieldChecks)))
  expect_true(all(v54$tableChecks$cdmTableName %in% checks$tableChecks$cdmTableName))
})
