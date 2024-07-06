library(testthat)

test_that("Installation check works", {
  result <- DataQualityDashboard:::is_installed("SqlRender")
  expect_true(result)
  expect_null(DataQualityDashboard:::ensure_installed("SqlRender"))
})

# When devtools::load_all is run, create symbolic link for sql directory
# Allows testing with devtools::test
if (Sys.getenv("DEVTOOLS_LOAD") == "true") {
  print("setting sql folder symbolic link")
  packageRoot <- normalizePath(system.file("..", package = "DataQualityDashboard"))
  # Create symbolic link so code can be used in devtools::test()
  R.utils::createLink(link = file.path(packageRoot, "sql"), system.file("sql", package = "DataQualityDashboard"))
  options("use.devtools.sql_shim" = TRUE)
}
options(connectionObserver = NULL)
