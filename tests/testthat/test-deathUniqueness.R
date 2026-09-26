library(testthat)

for (cdmVersion in c("5.2", "5.3", "5.4")) {
  test_that(paste("DEATH.person_id is unique in CDM", cdmVersion), {
    checks <- listDqChecks(cdmVersion = cdmVersion)
    deathRow <- checks$fieldChecks$cdmTableName == "DEATH" &
      checks$fieldChecks$cdmFieldName == "person_id"
    deathField <- checks$fieldChecks[deathRow, ]

    expect_equal(nrow(deathField), 1L)
    expect_equal(deathField$isPrimaryKey, "Yes")
    expect_equal(deathField$isPrimaryKeyThreshold, 0)
    expect_equal(deathField$isForeignKey, "Yes")
    expect_equal(deathField$isRequired, "Yes")
  })
}
