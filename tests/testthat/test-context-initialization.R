test_that("creating a context is safe as the first context API call", {
  script <- tempfile(fileext = ".R")
  output <- tempfile(fileext = ".log")
  on.exit(unlink(c(script, output)))
  writeLines(c(
    sprintf(".libPaths(%s)", paste(deparse(.libPaths()), collapse = "")),
    "Sys.setenv(CUDA_VISIBLE_DEVICES = '')",
    "library(RCOMPSs)",
    "RCOMPSs.CreateRunContext('first')",
    "stopifnot(setequal(RCOMPSs.GetAllContextNames(), c('default', 'first')))",
    "RCOMPSs.SetOperationContext('first')",
    "stopifnot(RCOMPSs.GetOperationPlacement('first') == 'CPU')",
    "RCOMPSs.DeleteRunContext('first')",
    "stopifnot(identical(RCOMPSs.GetAllContextNames(), 'default'))",
    "for (i in 1:100) {",
    "  RCOMPSs.CreateRunContext('cycle')",
    "  RCOMPSs.SetOperationContext('cycle')",
    "  RCOMPSs.SetRunMode('cycle', 'async')",
    "  stopifnot(RCOMPSs.GetRunMode('cycle') == 'ASYNC')",
    "  RCOMPSs.SyncContext('cycle')",
    "  RCOMPSs.FinalizeRunContext('cycle')",
    "  RCOMPSs.DeleteRunContext('cycle')",
    "  stopifnot(RCOMPSs.GetNumOfContexts() == 1)",
    "}",
    "RCOMPSs.SyncAll()",
    "cat('PASS fresh creation and 100 lifecycle cycles\\n')"
  ), script)
  # Isolate each run: an earlier test must not initialize the singleton and
  # conceal the first-call regression; crashes must not kill the test runner.
  for (i in 1:3) {
    status <- system2(file.path(R.home("bin"), "Rscript"),
                      c("--vanilla", shQuote(script)),
                      stdout = output, stderr = output)
    expect_equal(status, 0L, info = paste(readLines(output), collapse = "\n"))
  }
})

test_that("context queries work with no visible GPU", {
  script <- tempfile(fileext = ".R")
  output <- tempfile(fileext = ".log")
  on.exit(unlink(c(script, output)))
  writeLines(c(
    sprintf(".libPaths(%s)", paste(deparse(.libPaths()), collapse = "")),
    "Sys.setenv(CUDA_VISIBLE_DEVICES = '')",
    "library(RCOMPSs)",
    "stopifnot(identical(RCOMPSs.GetAllContextNames(), 'default'))",
    "stopifnot(RCOMPSs.GetNumOfContexts() == 1)",
    "stopifnot(RCOMPSs.GetOperationPlacement() == 'CPU')",
    "RCOMPSs.SetOperationPlacement('CPU')",
    "RCOMPSs.SetRunMode('async')",
    "stopifnot(RCOMPSs.GetRunMode() == 'ASYNC')",
    "RCOMPSs.SyncAll()"
  ), script)
  status <- system2(file.path(R.home("bin"), "Rscript"),
                    c("--vanilla", shQuote(script)),
                    stdout = output, stderr = output)
  expect_equal(status, 0L, info = paste(readLines(output), collapse = "\n"))
})
