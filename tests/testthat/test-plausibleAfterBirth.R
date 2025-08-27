library(testthat)

test_that("plausibleAfterBirth allows events on same day as birth (issue #561)", {
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(outputFolder, recursive = TRUE))

  connection <- DatabaseConnector::connect(connectionDetailsPlausibleAfterBirth)

  # Set up test data: person with birth_datetime and visit on same day
  DatabaseConnector::executeSql(connection, "
    -- Update person 1 to have a specific birth_datetime
    UPDATE person
    SET birth_datetime = '1990-01-15 10:00:00'
    WHERE person_id = 1;
  ")

  # Truncate visit_occurrence and add only the test row
  DatabaseConnector::executeSql(connection, "
    DELETE FROM visit_occurrence;

    INSERT INTO visit_occurrence
    (visit_occurrence_id, person_id, visit_concept_id, visit_start_date, visit_start_datetime, visit_end_date, visit_end_datetime, visit_type_concept_id)
    VALUES
    (1, 1, 9201, '1990-01-15', '1990-01-15 10:00:00', '1990-01-15', '1990-01-15 10:00:00', 44818517);
  ")

  DatabaseConnector::disconnect(connection)

  # Run the plausibleAfterBirth check
  results <- executeDqChecks(
    connectionDetails = connectionDetailsPlausibleAfterBirth,
    cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
    resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
    cdmSourceName = "Eunomia",
    checkNames = "plausibleAfterBirth",
    tablesToExclude = c("COST", "CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN"),
    outputFolder = outputFolder,
    writeToTable = FALSE
  )

  # Get results for visit_occurrence.visit_start_date
  r <- results$CheckResults[results$CheckResults$checkName == "plausibleAfterBirth" &
    results$CheckResults$cdmTableName == "VISIT_OCCURRENCE" &
    results$CheckResults$cdmFieldName == "VISIT_START_DATE", ]

  # Debug: check what columns exist
  cat("Available columns in CheckResults:\n")
  print(colnames(results$CheckResults))

  # Debug: check all plausibleAfterBirth results
  cat("\nAll plausibleAfterBirth results:\n")
  print(results$CheckResults[results$CheckResults$checkName == "plausibleAfterBirth", ])

  # Debug: check all results for visit_occurrence
  cat("\nAll results for visit_occurrence:\n")
  visit_results <- results$CheckResults[grepl("visit", tolower(results$CheckResults$cdmTableName)), ]
  print(visit_results)

  # Should have 0 violations (event on same day as birth should be allowed)
  expect_equal(r$numViolatedRows, 0)
})
