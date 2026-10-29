# Both paths run as one GPU-constrained COMPSs task, with identical FP64
# tile GEMM dimensions and C <- alpha*A*B + beta*C recurrence.
gemm_pipeline <- function(A, B, C, tile, steps, resident) {
  name <- "gemm_pipeline"
  if(!name %in% RCOMPSs::RCOMPSs.GetAllContextNames()) {
    RCOMPSs::RCOMPSs.CreateRunContext(name)
    RCOMPSs::RCOMPSs.SetOperationPlacement(name,"GPU")
    RCOMPSs::RCOMPSs.SetRunMode(name,"async")
  }
  RCOMPSs::RCOMPSs.SetOperationContext(name)
  if(resident) {
    a <- RCOMPSs::rcompss_gpu_matrix_upload(A)
    on.exit(RCOMPSs::rcompss_gpu_matrix_release(a),add=TRUE)
    b <- RCOMPSs::rcompss_gpu_matrix_upload(B)
    on.exit(RCOMPSs::rcompss_gpu_matrix_release(b),add=TRUE)
    c <- RCOMPSs::rcompss_gpu_matrix_upload(C)
    on.exit(RCOMPSs::rcompss_gpu_matrix_release(c),add=TRUE)
    for(i in seq_len(steps)) RCOMPSs::rcompss_gpu_matrix_gemm(a,b,c,.51,-.42,tile)
    RCOMPSs::rcompss_gpu_matrix_download(c)
  } else {
    kk <- split(seq_len(ncol(A)),(seq_len(ncol(A))-1L)%/%tile)
    at <- lapply(kk,function(k)A[,k,drop=FALSE])
    bt <- lapply(kk,function(k)B[k,,drop=FALSE])
    for(i in seq_len(steps)) C<-RCOMPSs::rcompss_gemm_tile_reduce(at,bt,C,.51,-.42,TRUE)
    C
  }
}
