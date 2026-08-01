#!/usr/bin/env Rscript
# COMPSs task test for cuBLAS Level-3 R exports (GPU worker).
# Pair: test_gpu_blas_solver_set3_functions.R (tasks) + this file (driver).
#
# Typical run:
#   runcompss --lang=r --resources=test_resources_1gpu.xml --tracing test_gpu_blas_solver_set3_main.R

library(RCOMPSs)

source("test_gpu_blas_solver_set3_functions.R")

# Initialize COMPSs (required before constraint()/task())
compss_start()

# Apply GPU constraint and task decorator
# Note: constraint() must be applied BEFORE task()
gpu_blas_solver_set3_constrained <- constraint(gpu_blas_solver_set3_task, processors = list(
  list(processorType = "CPU", computingUnits = "1"),
  list(processorType = "GPU", computingUnits = "1")
))
gpu_blas_solver_set3_constrained <- task(
  gpu_blas_solver_set3_constrained,
  "test_gpu_blas_solver_set3_functions.R",
  return_value = TRUE
)

cat("=== GPU BLAS (cuBLAS Level-3) COMPSs test (set 3) ===\n")
cat("Functions: DSCAL, DTRMM, DTRSM\n")
cat("Run with GPU resources, e.g.:\n")
cat("  runcompss --lang=r --resources=test_resources_gpu.xml test_gpu_blas_solver_set3_main.R\n\n")
flush.console()

main <- function() {
  cat("Submitting gpu_blas_solver_set3_task (DSCAL, DTRMM, DTRSM)...\n")
  flush.console()

  fut <- gpu_blas_solver_set3_constrained()
  out <- compss_wait_on(fut)

  cat("Result:\n")
  print(out)
  if (!isTRUE(out$ok)) {
    msg <- if (is.list(out) && length(out$error)) out$error else "task did not return ok=TRUE"
    stop("gpu_blas_solver_set3_task failed: ", msg)
  }
  cat("All DSCAL/DTRMM/DTRSM checks passed inside COMPSs task.\n")
  invisible(TRUE)
}

main()
compss_stop()

cat("\n=== test_gpu_blas_solver_set3_main.R completed ===\n")
