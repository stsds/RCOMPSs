# GPU cuBLAS Level-1/2 smoke tests for COMPSs (set 2).
# Functions: rcompss_gpu_dgemv, rcompss_gpu_ddot, rcompss_gpu_dnrm2

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
gpu_blas_solver_set2_run_checks <- function() {
  tol <- DEFAULT_GPU_BLAS_TEST_TOL

  # ----- cuBLAS DGEMV -----
  A <- matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2)
  x <- c(1, 2)
  y_gpu <- RCOMPSs::rcompss_gpu_dgemv(A, x)
  y_ref <- A %*% x
  if (!within_gpu_tolerance(y_gpu, y_ref, tol)) {
    stop("DGEMV (A %*% x) failed: max abs diff ", max_abs_diff(y_gpu, y_ref))
  }

  x_t <- c(1, 2, 3)
  y_t_gpu <- RCOMPSs::rcompss_gpu_dgemv(A, x_t, trans = TRUE)
  y_t_ref <- t(A) %*% x_t
  if (!within_gpu_tolerance(y_t_gpu, y_t_ref, tol)) {
    stop("DGEMV (t(A) %*% x) failed: max abs diff ", max_abs_diff(y_t_gpu, y_t_ref))
  }

  alpha <- 2.0
  beta <- 0.5
  y0 <- c(1, 1, 1)
  y_ab_gpu <- RCOMPSs::rcompss_gpu_dgemv(A, x, alpha = alpha, beta = beta, y0 = y0)
  y_ab_ref <- alpha * (A %*% x) + beta * y0
  if (!within_gpu_tolerance(y_ab_gpu, y_ab_ref, tol)) {
    stop("DGEMV alpha/beta failed: max abs diff ", max_abs_diff(y_ab_gpu, y_ab_ref))
  }

  # ----- cuBLAS DDOT -----
  v1 <- c(1, 3, 5, 7)
  v2 <- c(2, 4, 6, 8)
  dot_gpu <- RCOMPSs::rcompss_gpu_ddot(v1, v2)
  dot_ref <- sum(v1 * v2)
  if (!scalar_within_gpu_tolerance(dot_gpu, dot_ref)) {
    stop("DDOT failed: got ", dot_gpu, " expected ", dot_ref)
  }

  # ----- cuBLAS DNRM2 -----
  nrm_gpu <- RCOMPSs::rcompss_gpu_dnrm2(v1)
  nrm_ref <- sqrt(sum(v1 * v1))
  if (!scalar_within_gpu_tolerance(nrm_gpu, nrm_ref)) {
    stop("DNRM2 failed: got ", nrm_gpu, " expected ", nrm_ref)
  }

  list(
    dgemv = y_gpu,
    dgemv_trans = y_t_gpu,
    dgemv_alpha_beta = y_ab_gpu,
    ddot = dot_gpu,
    dnrm2 = nrm_gpu
  )
}

gpu_blas_solver_set2_run_local_tests <- function() {
  ensure_rcompss_namespace()
  ensure_gpu_blas_context()
  gpu_blas_solver_set2_run_checks()
}

# -----------------------------------------------------------------------------
# COMPSs task
# -----------------------------------------------------------------------------
gpu_blas_solver_set2_task <- function() {
  tryCatch(
    {
      ensure_rcompss_namespace()
      ensure_gpu_blas_context("gpu_task")
      res <- gpu_blas_solver_set2_run_checks()
      list(ok = TRUE, results = res)
    },
    error = function(e) {
      list(ok = FALSE, error = conditionMessage(e))
    }
  )
}
