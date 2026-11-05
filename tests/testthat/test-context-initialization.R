test_that("creating a context is safe as the first context API call", {
  # CUDA builds currently initialize a GPU even for CPU contexts. Opt in only
  # on hosts with a usable GPU, or when testing a CPU-only build.
  skip_if(Sys.getenv("RCOMPSs_TEST_CONTEXTS") != "true",
          "Set RCOMPSs_TEST_CONTEXTS=true on a supported context-test host")
  script <- tempfile(fileext = ".R")
  output <- tempfile(fileext = ".log")
  on.exit(unlink(c(script, output)))
  writeLines(c(
    sprintf(".libPaths(%s)", paste(deparse(.libPaths()), collapse = "")),
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
