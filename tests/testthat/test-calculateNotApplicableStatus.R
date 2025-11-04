library(testthat)

test_that("measurePersonCompleteness should not be marked as not applicable when table is empty", {
  # Create a mock check result for measurePersonCompleteness with tableIsEmpty = TRUE
  mockCheckResult <- data.frame(
    checkName = "measurePersonCompleteness",
    cdmTableName = "DEVICE_EXPOSURE",
    isError = 0,
    tableIsMissing = FALSE,
    fieldIsMissing = FALSE,
    tableIsEmpty = TRUE,
    fieldIsEmpty = FALSE,
    conceptIsMissing = FALSE,
    conceptAndUnitAreMissing = FALSE
  )

  # Test that .applyNotApplicable returns 0 (not applicable = FALSE) for measurePersonCompleteness
  # when tableIsEmpty is TRUE but tableIsMissing is FALSE
  result <- DataQualityDashboard:::.applyNotApplicable(mockCheckResult)
  expect_equal(result, 0)
})

test_that("measurePersonCompleteness should be marked as not applicable when table is missing", {
  # Create a mock check result for measurePersonCompleteness with tableIsMissing = TRUE
  mockCheckResult <- data.frame(
    checkName = "measurePersonCompleteness",
    cdmTableName = "DEVICE_EXPOSURE",
    isError = 0,
    tableIsMissing = TRUE,
    fieldIsMissing = FALSE,
    tableIsEmpty = FALSE,
    fieldIsEmpty = FALSE,
    conceptIsMissing = FALSE,
    conceptAndUnitAreMissing = FALSE
  )

  # Test that .applyNotApplicable returns 1 (not applicable = TRUE) for measurePersonCompleteness
  # when tableIsMissing is TRUE
  result <- DataQualityDashboard:::.applyNotApplicable(mockCheckResult)
  expect_equal(result, 1)
})

test_that("Not Applicable status Table Empty", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  # Make sure the device exposure table is empty
  connection <- DatabaseConnector::connect(connectionDetailsEunomiaNaChecks)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  DatabaseConnector::executeSql(connection, "DELETE FROM DEVICE_EXPOSURE;")

  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomiaNaChecks,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = c("cdmTable", "cdmField", "measureValueCompleteness"),
      # Eunomia COST table has misspelled 'REVEUE_CODE_SOURCE_VALUE'
      tablesToExclude = c("COST", "CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN"),
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  r <- results$CheckResults[results$CheckResults$checkName == "measureValueCompleteness" &
    results$CheckResults$tableName == "device_exposure", ]
  expect_true(all(r$notApplicable == 1))
})

test_that("measureConditionEraCompleteness Not Applicable if condition_occurrence empty", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  # Remove records from Condition Occurrence
  connection <- DatabaseConnector::connect(connectionDetailsEunomiaNaChecks)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  DatabaseConnector::executeSql(connection, "CREATE TABLE CONDITION_OCCURRENCE_BACK AS SELECT * FROM CONDITION_OCCURRENCE;")
  DatabaseConnector::executeSql(connection, "DELETE FROM CONDITION_OCCURRENCE;")

  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomiaNaChecks,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = c("cdmTable", "cdmField", "measureValueCompleteness", "measureConditionEraCompleteness"),
      # Eunomia COST table has misspelled 'REVEUE_CODE_SOURCE_VALUE'
      tablesToExclude = c("COST", "CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN"),
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  # Reinstate Condition Occurrence
  DatabaseConnector::executeSql(connection, "INSERT INTO CONDITION_OCCURRENCE SELECT * FROM CONDITION_OCCURRENCE_BACK;")
  DatabaseConnector::executeSql(connection, "DROP TABLE CONDITION_OCCURRENCE_BACK;")

  r <- results$CheckResults[results$CheckResults$checkName == "measureConditionEraCompleteness", ]
  expect_true(r$notApplicable == 1)
})

test_that("measureConditionEraCompleteness Fails if condition_era empty", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  # Remove records from Condition Era
  connection <- DatabaseConnector::connect(connectionDetailsEunomiaNaChecks)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  DatabaseConnector::executeSql(connection, "CREATE TABLE CONDITION_ERA_BACK AS SELECT * FROM CONDITION_ERA;")
  DatabaseConnector::executeSql(connection, "DELETE FROM CONDITION_ERA;")

  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomiaNaChecks,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = c("cdmTable", "cdmField", "measureValueCompleteness", "measureConditionEraCompleteness"),
      # Eunomia COST table has misspelled 'REVEUE_CODE_SOURCE_VALUE'
      tablesToExclude = c("COST", "CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN"),
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  # Reinstate the Condition Era
  DatabaseConnector::executeSql(connection, "INSERT INTO CONDITION_ERA SELECT * FROM CONDITION_ERA_BACK;")
  DatabaseConnector::executeSql(connection, "DROP TABLE CONDITION_ERA_BACK;")

  r <- results$CheckResults[results$CheckResults$checkName == "measureConditionEraCompleteness", ]
  expect_true(r$failed == 1)
})

test_that("measurePersonCompleteness NOT marked as Not Applicable when table is empty", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  # Remove records from Device Exposure to make it empty
  connection <- DatabaseConnector::connect(connectionDetailsEunomiaNaChecks)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  DatabaseConnector::executeSql(connection, "CREATE TABLE OBSERVATION_PERIOD_BACK AS SELECT * FROM OBSERVATION_PERIOD;")
  DatabaseConnector::executeSql(connection, "DELETE FROM OBSERVATION_PERIOD;")

  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomiaNaChecks,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      checkNames = c("cdmTable", "cdmField", "measureValueCompleteness", "measurePersonCompleteness"),
      # Eunomia COST table has misspelled 'REVEUE_CODE_SOURCE_VALUE'
      tablesToExclude = c("COST", "CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN"),
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  # Reinstate Device Exposure
  DatabaseConnector::executeSql(connection, "INSERT INTO OBSERVATION_PERIOD SELECT * FROM OBSERVATION_PERIOD_BACK;")
  DatabaseConnector::executeSql(connection, "DROP TABLE OBSERVATION_PERIOD_BACK;")

  # measurePersonCompleteness should NOT be marked as not applicable when table is empty
  r <- results$CheckResults[results$CheckResults$checkName == "measurePersonCompleteness" &
    results$CheckResults$cdmTableName == "OBSERVATION_PERIOD", ]
  expect_true(r$notApplicable == 0)

  # It should fail because the threshold is 100% and all persons have 0 records in empty table
  expect_true(r$failed == 1)
})

test_that("NA applied correctly when table or field is missing", {
  # measurePersonCompleteness with isError=1 and tableIsMissing=TRUE should be NA
  mockCheckResult <- data.frame(
    checkName = "measurePersonCompleteness",
    cdmTableName = "FOO",
    cdmFieldName = NA,
    isError = 1,
    tableIsMissing = TRUE,
    fieldIsMissing = FALSE,
    tableIsEmpty = FALSE,
    fieldIsEmpty = FALSE,
    conceptIsMissing = FALSE,
    conceptAndUnitAreMissing = FALSE
  )
  result <- DataQualityDashboard:::.applyNotApplicable(mockCheckResult)
  expect_equal(result, 1)

  # measureValueCompleteness with isError=1 and fieldIsMissing=TRUE should be NA
  mockCheckResult <- data.frame(
    checkName = "measureValueCompleteness",
    cdmTableName = "OBSERVATION",
    cdmFieldName = "bar",
    isError = 1,
    tableIsMissing = FALSE,
    fieldIsMissing = TRUE,
    tableIsEmpty = FALSE,
    fieldIsEmpty = FALSE,
    conceptIsMissing = FALSE,
    conceptAndUnitAreMissing = FALSE
  )
  result <- DataQualityDashboard:::.applyNotApplicable(mockCheckResult)
  expect_equal(result, 1)
})

test_that(".applyNotApplicable handles cdmTable and cdmField correctly", {
  # cdmTable should NEVER be NA, no matter what
  # Test with missing table
  mockCheckResult <- data.frame(
    checkName = "cdmTable",
    cdmTableName = "FOO",
    cdmFieldName = NA,
    isError = 0,
    tableIsMissing = TRUE,
    fieldIsMissing = FALSE,
    tableIsEmpty = FALSE,
    fieldIsEmpty = FALSE,
    conceptIsMissing = FALSE,
    conceptAndUnitAreMissing = FALSE
  )
  result <- DataQualityDashboard:::.applyNotApplicable(mockCheckResult)
  expect_equal(result, 0)

  # Test with empty table
  mockCheckResult <- data.frame(
    checkName = "cdmTable",
    cdmTableName = "FOO",
    cdmFieldName = NA,
    isError = 0,
    tableIsMissing = FALSE,
    fieldIsMissing = FALSE,
    tableIsEmpty = TRUE,
    fieldIsEmpty = FALSE,
    conceptIsMissing = FALSE,
    conceptAndUnitAreMissing = FALSE
  )
  result <- DataQualityDashboard:::.applyNotApplicable(mockCheckResult)
  expect_equal(result, 0)

  # Test with error
  mockCheckResult <- data.frame(
    checkName = "cdmTable",
    cdmTableName = "FOO",
    cdmFieldName = NA,
    isError = 1,
    tableIsMissing = FALSE,
    fieldIsMissing = FALSE,
    tableIsEmpty = FALSE,
    fieldIsEmpty = FALSE,
    conceptIsMissing = FALSE,
    conceptAndUnitAreMissing = FALSE
  )
  result <- DataQualityDashboard:::.applyNotApplicable(mockCheckResult)
  expect_equal(result, 0)

  # cdmField should only be NA if table is missing, otherwise never NA
  # Test with missing table (should BE NA)
  mockCheckResult <- data.frame(
    checkName = "cdmField",
    cdmTableName = "OBSERVATION",
    cdmFieldName = "bar",
    isError = 0,
    tableIsMissing = TRUE,
    fieldIsMissing = FALSE,
    tableIsEmpty = FALSE,
    fieldIsEmpty = FALSE,
    conceptIsMissing = FALSE,
    conceptAndUnitAreMissing = FALSE
  )
  result <- DataQualityDashboard:::.applyNotApplicable(mockCheckResult)
  expect_equal(result, 1)

  # Test with missing field but table exists (should NOT be NA)
  mockCheckResult <- data.frame(
    checkName = "cdmField",
    cdmTableName = "OBSERVATION",
    cdmFieldName = "bar",
    isError = 0,
    tableIsMissing = FALSE,
    fieldIsMissing = TRUE,
    tableIsEmpty = FALSE,
    fieldIsEmpty = FALSE,
    conceptIsMissing = FALSE,
    conceptAndUnitAreMissing = FALSE
  )
  result <- DataQualityDashboard:::.applyNotApplicable(mockCheckResult)
  expect_equal(result, 0)

  # Test with empty table (should NOT be NA)
  mockCheckResult <- data.frame(
    checkName = "cdmField",
    cdmTableName = "OBSERVATION",
    cdmFieldName = "bar",
    isError = 0,
    tableIsMissing = FALSE,
    fieldIsMissing = FALSE,
    tableIsEmpty = TRUE,
    fieldIsEmpty = FALSE,
    conceptIsMissing = FALSE,
    conceptAndUnitAreMissing = FALSE
  )
  result <- DataQualityDashboard:::.applyNotApplicable(mockCheckResult)
  expect_equal(result, 0)
})
