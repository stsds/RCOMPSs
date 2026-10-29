# One task reduces all k tile pairs for one output tile.
tile_gemm_cpu_reduce <- function(A, B, C, alpha, beta) {
  RCOMPSs::rcompss_gemm_tile_reduce(A, B, C, alpha, beta, gpu = FALSE)
}

tile_gemm_gpu_reduce <- function(A, B, C, alpha, beta) {
  name <- "tiled_gemm_reduce"
  if (!name %in% RCOMPSs::RCOMPSs.GetAllContextNames()) {
    RCOMPSs::RCOMPSs.CreateRunContext(name)
    RCOMPSs::RCOMPSs.SetOperationPlacement(name, "GPU")
    RCOMPSs::RCOMPSs.SetRunMode(name, "async")
  }
  RCOMPSs::RCOMPSs.SetOperationContext(name)
  # The native reduction synchronizes before returning; C stays on the GPU
  # across k updates, while A/B buffers are allocated once and reused.
  RCOMPSs::rcompss_gemm_tile_reduce(A, B, C, alpha, beta, gpu = TRUE)
}
