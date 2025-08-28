library(testthat)

test_that("Installation check works", {
  result <- DataQualityDashboard:::is_installed("SqlRender")
  expect_true(result)
  expect_null(DataQualityDashboard:::ensure_installed("SqlRender"))
})

# When devtools::load_all is run, create symbolic link for sql directory
# Allows testing with devtools::test
# Only run in local development, not in CI/covr
if (Sys.getenv("DEVTOOLS_LOAD") == "true" &&
  !identical(Sys.getenv("CI"), "true") &&
  !identical(Sys.getenv("COVR"), "true")) {
  print("setting sql folder symbolic link")
  packageRoot <- normalizePath(system.file("..", package = "DataQualityDashboard"))
  # Create symbolic link so code can be used in devtools::test()
  tryCatch(
    {
      if (requireNamespace("R.utils", quietly = TRUE)) {
        R.utils::createLink(link = file.path(packageRoot, "sql"), system.file("sql", package = "DataQualityDashboard"))
        options("use.devtools.sql_shim" = TRUE)
      } else {
        # Fallback: create a simple file.copy if R.utils is not available
        sqlLinkPath <- file.path(packageRoot, "sql")
        sqlPackagePath <- system.file("sql", package = "DataQualityDashboard")
        if (!dir.exists(sqlLinkPath)) {
          dir.create(sqlLinkPath, recursive = TRUE)
        }
        file.copy(from = sqlPackagePath, to = dirname(sqlLinkPath), recursive = TRUE, overwrite = TRUE)
        options("use.devtools.sql_shim" = TRUE)
      }
    },
    error = function(e) {
      warning("Failed to create symbolic link for SQL directory: ", e$message)
      # Continue without the symbolic link - the package should still work
    }
  )
}
options(connectionObserver = NULL)
