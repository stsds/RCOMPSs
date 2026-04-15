# GPU cuBLAS / cuSOLVER smoke tests for COMPSs (set 1).
# Functions: rcompss_gpu_dgemm, rcompss_gpu_daxpy, rcompss_gpu_dpotrf

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
gpu_blas_solver_run_checks <- function() {
  tol <- DEFAULT_GPU_BLAS_TEST_TOL

  # ----- cuBLAS DGEMM -----
  I2 <- diag(2)
  C0 <- RCOMPSs::rcompss_gpu_dgemm(I2, I2)
  if (!within_gpu_tolerance(C0, I2, tol)) {
    stop("DGEMM I*I failed: max abs diff ", max_abs_diff(C0, I2))
  }

  A <- matrix(c(1, 2, 3, 4, 5, 6), nrow = 3, ncol = 2)
  B <- matrix(c(1, 0, 1, 1, 0, 1), nrow = 2, ncol = 3)
  C_ref <- A %*% B
  C_gpu <- RCOMPSs::rcompss_gpu_dgemm(A, B)
  if (!within_gpu_tolerance(C_gpu, C_ref, tol)) {
    stop("DGEMM (A %*% B) failed: max abs diff ", max_abs_diff(C_gpu, C_ref))
  }

  # For transA=TRUE, op(A) is nrow(A)×ncol(A) -> t(A) is 2×3 here; B must have nrow = 3.
  B_ta <- matrix(c(1, 0, 2, 0, 1, 1, 1, 1, 0), nrow = 3, ncol = 3)
  C_atb <- RCOMPSs::rcompss_gpu_dgemm(A, B_ta, transA = TRUE)
  C_atb_ref <- t(A) %*% B_ta
  if (!within_gpu_tolerance(C_atb, C_atb_ref, tol)) {
    stop("DGEMM (t(A) %*% B) failed: max abs diff ", max_abs_diff(C_atb, C_atb_ref))
  }

  B2 <- matrix(c(7, 8, 9, 10, 11, 12), nrow = 3, ncol = 2)
  C_abt <- RCOMPSs::rcompss_gpu_dgemm(A, B2, transB = TRUE)
  C_abt_ref <- A %*% t(B2)
  if (!within_gpu_tolerance(C_abt, C_abt_ref, tol)) {
    stop("DGEMM (A %*% t(B)) failed: max abs diff ", max_abs_diff(C_abt, C_abt_ref))
  }

  A1 <- matrix(1:6, nrow = 2, ncol = 3)
  B1 <- matrix(10:15, nrow = 3, ncol = 2)
  C_tt <- RCOMPSs::rcompss_gpu_dgemm(A1, B1, transA = TRUE, transB = TRUE)
  C_tt_ref <- t(A1) %*% t(B1)
  if (!within_gpu_tolerance(C_tt, C_tt_ref, tol)) {
    stop("DGEMM (t(A) %*% t(B)) failed: max abs diff ", max_abs_diff(C_tt, C_tt_ref))
  }

  C_alpha <- RCOMPSs::rcompss_gpu_dgemm(A, B, alpha = 2.5)
  if (!within_gpu_tolerance(C_alpha, 2.5 * C_ref, tol)) {
    stop("DGEMM alpha scaling failed: max abs diff ", max_abs_diff(C_alpha, 2.5 * C_ref))
  }

  message("Running GPU stress DGEMM (3000x3000) x 10 ...")
  set.seed(123)
  N <- 3000
  reps <- 10
  A_big <- matrix(runif(N * N), nrow = N, ncol = N)
  B_big <- matrix(runif(N * N), nrow = N, ncol = N)
  for (i in seq_len(reps)) {
    C_big <- RCOMPSs::rcompss_gpu_dgemm(A_big, B_big)
    if (!is.matrix(C_big) || nrow(C_big) != N || ncol(C_big) != N) {
      stop("Stress DGEMM failed: unexpected output dimensions")
    }
  }

  # ----- cuBLAS DAXPY -----
  x <- c(1, 2, 3)
  y <- c(10, 20, 30)
  z <- RCOMPSs::rcompss_gpu_daxpy(x, y)
  if (!within_gpu_tolerance(z, x + y, tol)) {
    stop("DAXPY alpha=1 failed: max abs diff ", max_abs_diff(z, x + y))
  }
  z2 <- RCOMPSs::rcompss_gpu_daxpy(x, y, alpha = 3)
  if (!within_gpu_tolerance(z2, 3 * x + y, tol)) {
    stop("DAXPY alpha=3 failed: max abs diff ", max_abs_diff(z2, 3 * x + y))
  }

  # ----- cuSOLVER DPOTRF -----
  set.seed(42)
  M <- matrix(rnorm(25), 5, 5)
  A_spd <- crossprod(M) + 5 * diag(5)

  R_gpu <- RCOMPSs::rcompss_gpu_dpotrf(A_spd, upper = TRUE)
  R_up <- R_gpu
  R_up[lower.tri(R_up)] <- 0
  if (!within_gpu_tolerance(crossprod(R_up), A_spd, tol)) {
    stop("DPOTRF upper: R'R != A (max diff ", max_abs_diff(crossprod(R_up), A_spd), ")")
  }

  L_gpu <- RCOMPSs::rcompss_gpu_dpotrf(A_spd, upper = FALSE)
  L_lo <- L_gpu
  L_lo[upper.tri(L_lo)] <- 0
  if (!within_gpu_tolerance(L_lo %*% t(L_lo), A_spd, tol)) {
    stop("DPOTRF lower: LL' != A (max diff ", max_abs_diff(L_lo %*% t(L_lo), A_spd), ")")
  }

  list(
    dgemm = C_gpu,
    dgemm_alpha = C_alpha,
    daxpy = z,
    daxpy_alpha = z2,
    dpotrf_upper = R_gpu,
    dpotrf_lower = L_gpu
  )
}

# Standalone: ensure_rcompss_namespace(); ensure_gpu_blas_context(); gpu_blas_solver_run_checks()
gpu_blas_solver_run_local_tests <- function() {
  ensure_rcompss_namespace()
  ensure_gpu_blas_context()
  gpu_blas_solver_run_checks()
}

gpu_blas_solver_task <- function() {
  tryCatch(
    {
      ensure_rcompss_namespace()
      ensure_gpu_blas_context("gpu_task")
      res <- gpu_blas_solver_run_checks()
      list(ok = TRUE, results = res)
    },
    error = function(e) {
      list(ok = FALSE, error = conditionMessage(e))
    }
  )
}
