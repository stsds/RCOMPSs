# GPU cuBLAS Level-3 smoke tests for COMPSs (set 3).
# Functions: rcompss_gpu_dscal, rcompss_gpu_dtrmm, rcompss_gpu_dtrsm

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
gpu_blas_solver_set3_run_checks <- function() {
  tol <- DEFAULT_GPU_BLAS_TEST_TOL

  # ----- cuBLAS DSCAL -----
  x <- c(1, 2, 3, 4)
  alpha <- 3.5
  x_gpu <- RCOMPSs::rcompss_gpu_dscal(x, alpha = alpha)
  x_ref <- alpha * x
  if (!within_gpu_tolerance(x_gpu, x_ref, tol)) {
    stop("DSCAL failed: max abs diff ", max_abs_diff(x_gpu, x_ref))
  }

  # ----- cuBLAS DTRMM -----
  A <- matrix(c(1, 2, 3, 0, 4, 5, 0, 0, 6), nrow = 3, byrow = TRUE)
  B <- matrix(1:9, nrow = 3, byrow = TRUE)
  trmm_gpu <- RCOMPSs::rcompss_gpu_dtrmm(A, B, side = "L", uplo = "U", trans = "N", diag = "N", alpha = 2.0)
  trmm_ref <- 2.0 * (A %*% B)
  if (!within_gpu_tolerance(trmm_gpu, trmm_ref, tol)) {
    stop("DTRMM failed: max abs diff ", max_abs_diff(trmm_gpu, trmm_ref))
  }

  # ----- cuBLAS DTRSM -----
  trsm_gpu <- RCOMPSs::rcompss_gpu_dtrsm(A, B, side = "L", uplo = "U", trans = "N", diag = "N", alpha = 1.0)
  trsm_ref <- solve(A, B)
  if (!within_gpu_tolerance(trsm_gpu, trsm_ref, tol)) {
    stop("DTRSM failed: max abs diff ", max_abs_diff(trsm_gpu, trsm_ref))
  }

  list(
    dscal = x_gpu,
    dtrmm = trmm_gpu,
    dtrsm = trsm_gpu
  )
}

gpu_blas_solver_set3_run_local_tests <- function() {
  ensure_rcompss_namespace()
  ensure_gpu_blas_context()
  gpu_blas_solver_set3_run_checks()
}

# -----------------------------------------------------------------------------
# COMPSs task 
# -----------------------------------------------------------------------------
gpu_blas_solver_set3_task <- function() {
  tryCatch(
    {
      ensure_rcompss_namespace()
      ensure_gpu_blas_context("gpu_task")
      res <- gpu_blas_solver_set3_run_checks()
      list(ok = TRUE, results = res)
    },
    error = function(e) {
      list(ok = FALSE, error = conditionMessage(e))
    }
  )
}
