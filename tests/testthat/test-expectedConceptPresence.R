library(testthat)

.copyEunomiaDbForPresence <- function() {
  source <- Eunomia::getDatabaseFile(
    datasetName = "GiBleed",
    cdmVersion = "5.3",
    dbms = "sqlite",
    overwrite = FALSE
  )
  target <- tempfile(fileext = ".sqlite")
  file.copy(source, target)
  target
}

# measurePersonCompleteness is run alongside so that the result set is never
# empty (executeDqChecks cannot evaluate an empty result set).
.runExpectedConceptPresence <- function(connectionDetails, outputFolder, conceptCheckThresholdLoc = "default") {
  results <- withCallingHandlers(
    executeDqChecks(
      connectionDetails = connectionDetails,
      cdmDatabaseSchema = cdmDatabaseSchemaEunomia,
      resultsDatabaseSchema = resultsDatabaseSchemaEunomia,
      cdmSourceName = "Eunomia",
      cdmVersion = "5.3",
      checkNames = c("expectedConceptPresence", "measurePersonCompleteness"),
      conceptCheckThresholdLoc = conceptCheckThresholdLoc,
      outputFolder = outputFolder,
      writeToTable = FALSE
    ),
    warning = function(w) {
      if (grepl("^Missing check names", w$message)) {
        invokeRestart("muffleWarning")
      }
    }
  )
  results$CheckResults[results$CheckResults$checkName == "expectedConceptPresence", ]
}

# Writes a concept threshold file that expects `conceptId` in
# CONDITION_OCCURRENCE.condition_status_concept_id with the given threshold.
.writePresenceThresholdFile <- function(path, conceptId, threshold) {
  conceptChecks <- read.csv(
    system.file("csv", "OMOP_CDM_Concept_Level.csv", package = "DataQualityDashboard"),
    colClasses = "character", na.strings = ""
  )
  newRow <- conceptChecks[1, ]
  newRow[1, ] <- NA
  newRow$cdmTableName <- "CONDITION_OCCURRENCE"
  newRow$cdmFieldName <- "condition_status_concept_id"
  newRow$conceptId <- as.character(conceptId)
  newRow$conceptName <- "Test status"
  newRow$expectedConceptPresence <- "Yes"
  newRow$expectedConceptPresenceThreshold <- as.character(threshold)
  write.csv(rbind(conceptChecks, newRow), path, row.names = FALSE, na = "")
}

test_that("expectedConceptPresence does not run with the default concept thresholds", {
  testthat::skip_if_not_installed("Eunomia")
  dbFile <- .copyEunomiaDbForPresence()
  outputFolder <- tempfile("dqd_")
  on.exit(unlink(c(dbFile, outputFolder), recursive = TRUE))
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sqlite", server = dbFile)

  result <- .runExpectedConceptPresence(connectionDetails, outputFolder)
  expect_equal(nrow(result), 0)
})

test_that("expectedConceptPresence fails when the expected concept is under-represented", {
  testthat::skip_if_not_installed("Eunomia")
  dbFile <- .copyEunomiaDbForPresence()
  outputFolder <- tempfile("dqd_")
  thresholdFile <- tempfile(fileext = ".csv")
  on.exit(unlink(c(dbFile, outputFolder, thresholdFile), recursive = TRUE))
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sqlite", server = dbFile)

  statusConceptId <- 32899
  # Require at least 5% of records to carry the status concept
  .writePresenceThresholdFile(thresholdFile, statusConceptId, 95)

  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)
  total <- DatabaseConnector::querySql(connection, "SELECT COUNT(*) FROM condition_occurrence;")[1, 1]

  # No record has the concept: 100% violate, so the check fails
  none <- .runExpectedConceptPresence(connectionDetails, outputFolder, thresholdFile)
  expect_equal(nrow(none), 1)
  expect_equal(none$isError, 0)
  expect_equal(none$numViolatedRows, total)
  expect_equal(none$numDenominatorRows, total)
  expect_equal(none$failed, 1)

  # Give roughly 10% of records the concept (and NULL out some others, which
  # must still count as violations): the check now passes
  DatabaseConnector::executeSql(connection, sprintf("
    UPDATE condition_occurrence SET condition_status_concept_id = %d WHERE condition_occurrence_id %% 10 = 0;
    UPDATE condition_occurrence SET condition_status_concept_id = NULL WHERE condition_occurrence_id %% 10 = 1;",
    statusConceptId
  ))
  withConcept <- DatabaseConnector::querySql(
    connection,
    sprintf("SELECT COUNT(*) FROM condition_occurrence WHERE condition_status_concept_id = %d;", statusConceptId)
  )[1, 1]

  some <- .runExpectedConceptPresence(connectionDetails, outputFolder, thresholdFile)
  expect_equal(some$numViolatedRows, total - withConcept)
  expect_equal(some$failed, 0)
  expect_equal(some$passed, 1)
})
