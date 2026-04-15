# GPU cuSOLVER smoke tests for COMPSs (set 5).
# Function: rcompss_gpu_dpotrs

# Helpers inlined: COMPSs loads only this file for the task; nested source() is not supported.
# GPU BLAS/cuSOLVER vs R reference can differ from ~1e-15.
DEFAULT_GPU_BLAS_TEST_TOL <- 1e-8

ensure_rcompss_namespace <- function() {
  if (!requireNamespace("RCOMPSs", quietly = TRUE)) {
    stop("package 'RCOMPSs' is required (install it or set R_LIBS)", call. = FALSE)
  }
}

ensure_gpu_blas_context <- function(context_name = "gpu_task") {
  if (!context_name %in% RCOMPSs::rcompss_get_all_context_names()) {
    RCOMPSs::rcompss_create_gpu_context(context_name)
  }
  RCOMPSs::rcompss_set_operation_placement(context_name, "GPU")
  RCOMPSs::rcompss_set_run_mode(context_name, "SYNC")
  RCOMPSs::rcompss_set_operation_context(context_name)
  invisible(context_name)
}

max_abs_diff <- function(a, b) {
  max(abs(as.matrix(a) - as.matrix(b)))
}

within_gpu_tolerance <- function(a, b, tol = DEFAULT_GPU_BLAS_TEST_TOL) {
  max_abs_diff(a, b) <= tol
}

scalar_within_gpu_tolerance <- function(a, b,
                                        abs_tol = DEFAULT_GPU_BLAS_TEST_TOL,
                                        rel_tol = 1e-10) {
  da <- abs(as.numeric(a) - as.numeric(b))
  ref <- max(abs(as.numeric(a)), abs(as.numeric(b)), 1e-300)
  da <= max(abs_tol, rel_tol * ref)
}

# Core numeric checks only (assumes GPU operation context is already active).
gpu_blas_solver_set5_run_checks <- function() {
  tol <- DEFAULT_GPU_BLAS_TEST_TOL

  # ----- cuSOLVER DPOTRS -----
  set.seed(42)
  n <- 4
  M <- matrix(rnorm(n * n), n, n)
  A_spd <- crossprod(M) + 3 * diag(n)
  B <- matrix(rnorm(n * 2), n, 2)

  # Base R chol() returns upper-triangular factor by default
  cholA <- chol(A_spd)
  x_gpu <- RCOMPSs::rcompss_gpu_dpotrs(cholA, B, upper = TRUE)
  x_ref <- solve(A_spd, B)

  if (!within_gpu_tolerance(x_gpu, x_ref, tol)) {
    stop("DPOTRS failed: max abs diff ", max_abs_diff(x_gpu, x_ref))
  }

  list(
    dpotrs = x_gpu
  )
}

gpu_blas_solver_set5_run_local_tests <- function() {
  ensure_rcompss_namespace()
  ensure_gpu_blas_context()
  gpu_blas_solver_set5_run_checks()
}

# -----------------------------------------------------------------------------
# COMPSs task 
# -----------------------------------------------------------------------------
gpu_blas_solver_set5_task <- function() {
  tryCatch(
    {
      ensure_rcompss_namespace()
      ensure_gpu_blas_context("gpu_task")
      res <- gpu_blas_solver_set5_run_checks()
      list(ok = TRUE, results = res)
    },
    error = function(e) {
      list(ok = FALSE, error = conditionMessage(e))
    }
  )
}
