library(testthat)

test_that("Not Applicable status Table Empty", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  # Make sure the device exposure table is empty
  connection <- DatabaseConnector::connect(connectionDetailsEunomiaNaChecks)
  DatabaseConnector::executeSql(connection, "DELETE FROM DEVICE_EXPOSURE;")
  DatabaseConnector::disconnect(connection)

  results <- executeDqChecks(
    connectionDetails = connectionDetailsEunomiaNaChecks,
    cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    cdmSourceName = "Eunomia",
    checkNames = c("cdmTable", "cdmField", "measureValueCompleteness"),
    # Eunomia COST table has misspelled 'REVEUE_CODE_SOURCE_VALUE'
    tablesToExclude = c("COST", "CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN"),
    outputFolder = outputFolder,
    writeToTable = FALSE
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
  DatabaseConnector::executeSql(connection, "CREATE TABLE CONDITION_OCCURRENCE_BACK AS SELECT * FROM CONDITION_OCCURRENCE;")
  DatabaseConnector::executeSql(connection, "DELETE FROM CONDITION_OCCURRENCE;")
  DatabaseConnector::disconnect(connection)

  results <- executeDqChecks(
    connectionDetails = connectionDetailsEunomiaNaChecks,
    cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    cdmSourceName = "Eunomia",
    checkNames = c("cdmTable", "cdmField", "measureValueCompleteness", "measureConditionEraCompleteness"),
    # Eunomia COST table has misspelled 'REVEUE_CODE_SOURCE_VALUE'
    tablesToExclude = c("COST", "CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN"),
    outputFolder = outputFolder,
    writeToTable = FALSE
  )

  # Reinstate Condition Occurrence
  connection <- DatabaseConnector::connect(connectionDetailsEunomiaNaChecks)
  DatabaseConnector::executeSql(connection, "INSERT INTO CONDITION_OCCURRENCE SELECT * FROM CONDITION_OCCURRENCE_BACK;")
  DatabaseConnector::executeSql(connection, "DROP TABLE CONDITION_OCCURRENCE_BACK;")
  disconnect(connection)

  r <- results$CheckResults[results$CheckResults$checkName == "measureConditionEraCompleteness", ]
  expect_true(r$notApplicable == 1)
})

test_that("measureConditionEraCompleteness Fails if condition_era empty", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  # Remove records from Condition Era
  connection <- DatabaseConnector::connect(connectionDetailsEunomiaNaChecks)
  DatabaseConnector::executeSql(connection, "CREATE TABLE CONDITION_ERA_BACK AS SELECT * FROM CONDITION_ERA;")
  DatabaseConnector::executeSql(connection, "DELETE FROM CONDITION_ERA;")
  DatabaseConnector::disconnect(connection)

  results <- executeDqChecks(
    connectionDetails = connectionDetailsEunomiaNaChecks,
    cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    cdmSourceName = "Eunomia",
    checkNames = c("cdmTable", "cdmField", "measureValueCompleteness", "measureConditionEraCompleteness"),
    # Eunomia COST table has misspelled 'REVEUE_CODE_SOURCE_VALUE'
    tablesToExclude = c("COST", "CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN"),
    outputFolder = outputFolder,
    writeToTable = FALSE
  )

  # Reinstate the Condition Era
  connection <- DatabaseConnector::connect(connectionDetailsEunomiaNaChecks)
  DatabaseConnector::executeSql(connection, "INSERT INTO CONDITION_ERA SELECT * FROM CONDITION_ERA_BACK;")
  DatabaseConnector::executeSql(connection, "DROP TABLE CONDITION_ERA_BACK;")
  DatabaseConnector::disconnect(connection)

  r <- results$CheckResults[results$CheckResults$checkName == "measureConditionEraCompleteness", ]
  expect_true(r$failed == 1)
})
