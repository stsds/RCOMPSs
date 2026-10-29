# One task performs one tile update; C may be a future from the previous k step.
tile_gemm_cpu <- function(A, B, C, alpha, beta) {
  stopifnot(is.matrix(A), is.matrix(B), is.matrix(C),
            ncol(A) == nrow(B), nrow(C) == nrow(A), ncol(C) == ncol(B))
  alpha * (A %*% B) + beta * C
}

tile_gemm_gpu <- function(A, B, C, alpha, beta) {
  stopifnot(is.matrix(A), is.matrix(B), is.matrix(C),
            ncol(A) == nrow(B), nrow(C) == nrow(A), ncol(C) == ncol(B))
  # Context is cached inside each worker; inputs/results remain ordinary R tiles.
  name <- "tiled_gemm"
  if (!name %in% RCOMPSs::RCOMPSs.GetAllContextNames()) {
    RCOMPSs::RCOMPSs.CreateRunContext(name)
    RCOMPSs::RCOMPSs.SetOperationPlacement(name, "GPU")
    RCOMPSs::RCOMPSs.SetRunMode(name, "sync")
  }
  RCOMPSs::RCOMPSs.SetOperationContext(name)
  # Current GPU binding supports beta=0 only. Accumulation is on the host.
  RCOMPSs::rcompss_gpu_dgemm(A, B, alpha = alpha) + beta * C
}
