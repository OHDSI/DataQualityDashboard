library(testthat)

test_that('executeDqChecks with long-format Table-level matches executeDqChecks for equivalent thresholds', {
  testthat::skip_if_not_installed('Eunomia')

  connectionDetailsEunomia <- Eunomia::getEunomiaConnectionDetails()
  cdmDatabaseSchemaEunomia <- 'main'
  resultsDatabaseSchemaEunomia <- 'main'
  checkLevel <- 'TABLE'
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  r1 <- suppressWarnings(DataQualityDashboard::executeDqChecks(
    connectionDetails = connectionDetailsEunomia,
    cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    cdmSourceName = 'Eunomia',
    outputFolder = outputFolder,
    tableCheckThresholdExtensionLoc = long_OMOP_CDMv5.3_Table_Level,
    fieldCheckThresholdExtensionLoc = long_OMOP_CDMv5.3_Field_Level,
    conceptCheckThresholdExtensionLoc = long_OMOP_CDMv5.3_Concept_Level,
    checkLevel = checkLevel,
    writeToTable = FALSE
  ))

  r2 <- suppressWarnings(DataQualityDashboard::executeDqChecks(
    connectionDetails = connectionDetailsEunomia,
    cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    cdmSourceName = 'Eunomia',
    outputFolder = outputFolder,
    cdmVersion = '5.3',
    checkLevel = checkLevel,
    writeToTable = FALSE
  ))

  # Compare r1 and r2

  # CheckResults has the same number of rows and columns
  expect_equal(nrow(r1$CheckResults), nrow(r2$CheckResults))

  # CheckResults same values for all columns except executionTime and notesValue
  expect_equal(
    r1$CheckResults |> dplyr::select(-executionTime, -notesValue) |> dplyr::arrange(cdmTableName, checkName),
    r2$CheckResults |> dplyr::select(-executionTime, -notesValue) |> dplyr::arrange(cdmTableName, checkName),
    ignore_attr = c('row.names')
  )

  # Overview equal - same number of failures
  expect_equal(r1$Overview, r2$Overview)
})

test_that('executeDqChecks with long-format Field-level matches executeDqChecks for equivalent thresholds', {
  testthat::skip_if_not_installed('Eunomia')

  connectionDetailsEunomia <- Eunomia::getEunomiaConnectionDetails()
  cdmDatabaseSchemaEunomia <- 'main'
  resultsDatabaseSchemaEunomia <- 'main'
  checkLevel <- 'FIELD'
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  r1 <- suppressWarnings(DataQualityDashboard::executeDqChecks(
    connectionDetails = connectionDetailsEunomia,
    cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    cdmSourceName = 'Eunomia',
    outputFolder = outputFolder,
    tableCheckThresholdExtensionLoc = long_OMOP_CDMv5.3_Table_Level,
    fieldCheckThresholdExtensionLoc = long_OMOP_CDMv5.3_Field_Level,
    conceptCheckThresholdExtensionLoc = long_OMOP_CDMv5.3_Concept_Level,
    checkLevel = checkLevel,
    checkNames = c("plausibleTemporalAfter", "plausibleAfterBirth", "plausibleBeforeDeath", "plausibleStartBeforeEnd"),
    writeToTable = FALSE
  ))

  r2 <- suppressWarnings(DataQualityDashboard::executeDqChecks(
    connectionDetails = connectionDetailsEunomia,
    cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    cdmSourceName = 'Eunomia',
    outputFolder = outputFolder,
    cdmVersion = '5.3',
    checkLevel = checkLevel,
    checkNames = c("plausibleTemporalAfter", "plausibleAfterBirth", "plausibleBeforeDeath", "plausibleStartBeforeEnd"),
    writeToTable = FALSE
  ))

  # Compare r1 and r2

  # CheckResults has the same number of rows and columns
  expect_equal(nrow(r1$CheckResults), nrow(r2$CheckResults))

  # CheckResults same values for all columns except executionTime and notesValue
  expect_equal(
    r1$CheckResults |> dplyr::select(-executionTime, -notesValue) |> dplyr::arrange(cdmTableName, cdmFieldName, checkName),
    r2$CheckResults |> dplyr::select(-executionTime, -notesValue) |> dplyr::arrange(cdmTableName, cdmFieldName, checkName),
    ignore_attr = c('row.names')
  )

  # Overview equal - same number of failures
  expect_equal(r1$Overview, r2$Overview)
})

test_that('executeDqChecks with long-format Concept-level threshold matches executeDqChecks for equivalent thresholds', {
  testthat::skip_if_not_installed('Eunomia')

  connectionDetailsEunomia <- Eunomia::getEunomiaConnectionDetails()
  cdmDatabaseSchemaEunomia <- 'main'
  resultsDatabaseSchemaEunomia <- 'main'
  checkLevel <- 'CONCEPT'
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  r1 <- suppressWarnings(DataQualityDashboard::executeDqChecks(
    connectionDetails = connectionDetailsEunomia,
    cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    cdmSourceName = 'Eunomia',
    outputFolder = outputFolder,
    tableCheckThresholdExtensionLoc = long_OMOP_CDMv5.3_Table_Level,
    fieldCheckThresholdExtensionLoc = long_OMOP_CDMv5.3_Field_Level,
    conceptCheckThresholdExtensionLoc = long_OMOP_CDMv5.3_Concept_Level,
    checkLevel = checkLevel,
    writeToTable = FALSE
  ))

  r2 <- suppressWarnings(DataQualityDashboard::executeDqChecks(
    connectionDetails = connectionDetailsEunomia,
    cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    cdmSourceName = 'Eunomia',
    outputFolder = outputFolder,
    cdmVersion = '5.3',
    checkLevel = checkLevel,
    writeToTable = FALSE
  ))

  # Compare r1 and r2

  # CheckResults has the same number of rows and columns
  expect_equal(nrow(r1$CheckResults), nrow(r2$CheckResults))

  # CheckResults same values for all columns except executionTime and notesValue
  expect_equal(
    r1$CheckResults |> dplyr::select(-executionTime, -notesValue) |> dplyr::arrange(cdmTableName, cdmFieldName, checkName, conceptId, unitConceptId),
    r2$CheckResults |> dplyr::select(-executionTime, -notesValue) |> dplyr::arrange(cdmTableName, cdmFieldName, checkName, conceptId, unitConceptId),
    ignore_attr = c('row.names')
  )
  # Overview equal - same number of failures
  expect_equal(r1$Overview, r2$Overview)
})
