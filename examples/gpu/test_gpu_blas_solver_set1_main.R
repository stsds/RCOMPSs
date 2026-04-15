#!/usr/bin/env Rscript
# COMPSs task test for cuBLAS/cuSOLVER R exports (GPU worker), set 1.
# Pair: test_gpu_blas_solver_set1_functions.R (tasks) + this file (driver).
#
# Typical run (same pattern as vector-add GPU test):
#   runcompss --lang=r --resources=test_resources_gpu.xml --tracing test_gpu_blas_solver_set1_main.R

library(RCOMPSs)

source("test_gpu_blas_solver_set1_functions.R")

# Initialize COMPSs (required before constraint()/task() — sets MASTER_WORKING_DIR)
compss_start()

# Apply GPU constraint and task decorator (same pattern as test_gpu_vector_add_main.R).
# Note: constraint() must be applied BEFORE task()
gpu_blas_solver_constrained <- constraint(gpu_blas_solver_task, processors = list(
  list(processorType = "CPU", computingUnits = "1"),
  list(processorType = "GPU", computingUnits = "1")
))
gpu_blas_solver_constrained <- task(
  gpu_blas_solver_constrained,
  "test_gpu_blas_solver_set1_functions.R",
  return_value = TRUE
)

cat("=== GPU BLAS / cuSOLVER COMPSs test (set 1) ===\n")
cat("Run with GPU resources, e.g.:\n")
cat("  runcompss --lang=r --resources=test_resources_gpu.xml test_gpu_blas_solver_set1_main.R\n\n")
flush.console()

main <- function() {
  cat("=== COMPSs GPU task: cuBLAS / cuSOLVER bindings (set 1) ===\n")
  cat("Submitting gpu_blas_solver_task (DGEMM, DAXPY, DPOTRF)...\n")
  flush.console()

  fut <- gpu_blas_solver_constrained()
  out <- compss_wait_on(fut)

  cat("Result:\n")
  print(out)
  if (!isTRUE(out$ok)) {
    msg <- if (is.list(out) && length(out$error)) out$error else "task did not return ok=TRUE"
    stop("gpu_blas_solver_task failed: ", msg)
  }
  cat("All exposed cuBLAS/cuSOLVER R functions passed inside COMPSs task.\n")
  invisible(TRUE)
}

main()
compss_stop()

cat("\n=== test_gpu_blas_solver_set1_main.R completed ===\n")
