library(testthat)

test_that("fkClass values are rendered as a quoted SQL list", {
  expect_equal(DataQualityDashboard:::.formatSqlStringList("Ingredient"), "'Ingredient'")
  expect_equal(
    DataQualityDashboard:::.formatSqlStringList("Ingredient,Precise Ingredient"),
    "'Ingredient','Precise Ingredient'"
  )
  expect_equal(
    DataQualityDashboard:::.formatSqlStringList("Ingredient, Precise Ingredient"),
    "'Ingredient','Precise Ingredient'"
  )
})

test_that("fkClass allows multiple concept classes for DRUG_STRENGTH.ingredient_concept_id (issue #624)", {
  testthat::skip_if_not_installed("Eunomia")
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  connection <- DatabaseConnector::connect(connectionDetailsEunomiaFkClass)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)

  # Eunomia ships an empty DRUG_STRENGTH table; add one row per concept class of interest.
  # The vocabulary uses both Ingredient and Precise Ingredient concepts in ingredient_concept_id,
  # so only the Clinical Drug row should be counted as a violation.
  DatabaseConnector::executeSql(
    connection,
    "
    INSERT INTO concept
    (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
    VALUES
    (9000001, 'Test ingredient', 'Drug', 'RxNorm', 'Ingredient', 'S', 'T1', 0, 0, NULL),
    (9000002, 'Test precise ingredient', 'Drug', 'RxNorm', 'Precise Ingredient', NULL, 'T2', 0, 0, NULL),
    (9000003, 'Test clinical drug', 'Drug', 'RxNorm', 'Clinical Drug', 'S', 'T3', 0, 0, NULL);

    INSERT INTO drug_strength
    (drug_concept_id, ingredient_concept_id, amount_value, amount_unit_concept_id, valid_start_date, valid_end_date)
    VALUES
    (9000003, 9000001, 1, 8576, 0, 0),
    (9000003, 9000002, 1, 8576, 0, 0),
    (9000003, 9000003, 1, 8576, 0, 0);
    ",
    progressBar = FALSE,
    reportOverallTime = FALSE
  )

  # DRUG_STRENGTH is excluded by default, so pass an empty tablesToExclude.
  # fkClass is only defined for DRUG_ERA, DOSE_ERA and DRUG_STRENGTH.
  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetailsEunomiaFkClass,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      cdmVersion = "5.4",
      checkNames = "fkClass",
      tablesToExclude = c(),
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  checkResults <- results$CheckResults
  expect_length(stats::na.omit(checkResults$error), 0)

  drugStrength <- checkResults[checkResults$cdmTableName == "DRUG_STRENGTH" &
    checkResults$cdmFieldName == "INGREDIENT_CONCEPT_ID", ]
  expect_equal(nrow(drugStrength), 1)
  expect_true(grepl("NOT IN ('Ingredient','Precise Ingredient')", drugStrength$queryText, fixed = TRUE))
  expect_equal(drugStrength$numDenominatorRows, 3)
  expect_equal(drugStrength$numViolatedRows, 1)

  # Fields with a single allowed class are unaffected
  drugEra <- checkResults[checkResults$cdmTableName == "DRUG_ERA" &
    checkResults$cdmFieldName == "DRUG_CONCEPT_ID", ]
  expect_equal(nrow(drugEra), 1)
  expect_true(grepl("NOT IN ('Ingredient')", drugEra$queryText, fixed = TRUE))
  expect_equal(drugEra$numViolatedRows, 0)
})
