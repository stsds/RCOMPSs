# GPU BLAS/SOLVER smoke tests for COMPSs (set 4).
# Functions: rcompss_gpu_dsyrk, rcompss_gpu_dgetrf, rcompss_gpu_dgetrs

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
gpu_blas_solver_set4_run_checks <- function() {
  tol <- DEFAULT_GPU_BLAS_TEST_TOL

  # ----- cuBLAS DSYRK -----
  A <- matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2)
  alpha <- 1.5
  beta <- 0.5
  C0 <- diag(3)
  syrk_gpu <- RCOMPSs::rcompss_gpu_dsyrk(A, uplo = "U", trans = "N", alpha = alpha, beta = beta, C0 = C0)
  syrk_ref <- alpha * (A %*% t(A)) + beta * C0
  # DSYRK returns only the triangle indicated by `uplo`; compare that triangle.
  diff_upper <- max(abs(syrk_gpu[upper.tri(syrk_gpu, diag = TRUE)] -
                           syrk_ref[upper.tri(syrk_ref, diag = TRUE)]))
  if (diff_upper > tol) {
    stop("DSYRK failed (upper triangle): max abs diff ", diff_upper)
  }

  # ----- cuSOLVER DGETRF + DGETRS -----
  A_sq <- matrix(c(4, 3, 2,
                   3, 2, 1,
                   2, 1, 3), nrow = 3, byrow = TRUE)
  B <- matrix(c(1, 2, 3), nrow = 3, ncol = 1)

  lu <- RCOMPSs::rcompss_gpu_dgetrf(A_sq)
  if (!is.list(lu) || is.null(lu$LU) || is.null(lu$pivot)) {
    stop("DGETRF returned unexpected structure")
  }
  if (!is.null(lu$info) && lu$info != 0) {
    stop("DGETRF failed (info=", lu$info, ")")
  }

  x_gpu <- RCOMPSs::rcompss_gpu_dgetrs(lu$LU, lu$pivot, B, trans = FALSE)
  x_ref <- solve(A_sq, B)
  if (!within_gpu_tolerance(x_gpu, x_ref, tol)) {
    stop("DGETRS failed: max abs diff ", max_abs_diff(x_gpu, x_ref))
  }

  list(
    dsyrk = syrk_gpu,
    dgetrf = lu,
    dgetrs = x_gpu
  )
}

gpu_blas_solver_set4_run_local_tests <- function() {
  ensure_rcompss_namespace()
  ensure_gpu_blas_context()
  gpu_blas_solver_set4_run_checks()
}

# -----------------------------------------------------------------------------
# COMPSs task 
# -----------------------------------------------------------------------------
gpu_blas_solver_set4_task <- function() {
  tryCatch(
    {
      ensure_rcompss_namespace()
      ensure_gpu_blas_context("gpu_task")
      res <- gpu_blas_solver_set4_run_checks()
      list(ok = TRUE, results = res)
    },
    error = function(e) {
      list(ok = FALSE, error = conditionMessage(e))
    }
  )
}
