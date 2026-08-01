# GPU context and memory API
# Context: create/set placement and active context. Memory: allocate in R, copy, run kernel, free.

#' Set operation placement (CPU/GPU) for a context.
#' One arg = placement for "default" context; two args = (contextname, placement).
#' @param contextname Context name (default "default" when only placement is given).
#' @param placement "CPU" or "GPU".
#' @export
`RCOMPSs.SetOperationPlacement` <- function(contextname = "default", placement = NULL) {
  if (is.null(placement)) {
    placement <- contextname
    contextname <- "default"
  }
  rcompss_set_operation_placement(contextname, placement)
}

#' Get operation placement for a context.
#' @param contextname Context name (default "default").
#' @export
`RCOMPSs.GetOperationPlacement` <- function(contextname = "default") {
  rcompss_get_operation_placement(contextname)
}

#' Create a run context by name.
#' @param contextname Name of the new context.
#' @export
`RCOMPSs.CreateRunContext` <- function(contextname) {
  invisible(rcompss_create_gpu_context(contextname))
}

#' Set run mode (sync/async) for a context.
#' One arg = runmode for "default"; two args = (contextname, runmode).
#' @param contextname Context name (default "default" when only runmode is given).
#' @param runmode "sync" or "async".
#' @export
`RCOMPSs.SetRunMode` <- function(contextname = "default", runmode = NULL) {
  if (is.null(runmode)) {
    runmode <- contextname
    contextname <- "default"
  }
  invisible(rcompss_set_run_mode(contextname, runmode))
}

#' Get run mode for a context.
#' @param contextname Context name (default "default").
#' @export
`RCOMPSs.GetRunMode` <- function(contextname = "default") {
  rcompss_get_run_mode(contextname)
}

#' Set the active operation context.
#' @param contextname Context name to use for upcoming GPU operations.
#' @export
`RCOMPSs.SetOperationContext` <- function(contextname) {
  invisible(rcompss_set_operation_context(contextname))
}

#' Synchronize a context (wait for its stream).
#' @param contextname Context name.
#' @export
`RCOMPSs.SyncContext` <- function(contextname) {
  invisible(rcompss_sync_context(contextname))
}

#' Synchronize all contexts.
#' @export
`RCOMPSs.SyncAll` <- function() {
  invisible(rcompss_sync_all_contexts())
}

#' Get number of run contexts.
#' @export
`RCOMPSs.GetNumOfContexts` <- function() {
  rcompss_get_num_contexts()
}

#' Get all context names.
#' @export
`RCOMPSs.GetAllContextNames` <- function() {
  rcompss_get_all_context_names()
}

#' Delete a run context.
#' @param contextname Context name to delete.
#' @export
`RCOMPSs.DeleteRunContext` <- function(contextname) {
  invisible(rcompss_delete_context(contextname))
}

#' Finalize a run context (sync and free work buffers).
#' @param contextname Context name.
#' @export
`RCOMPSs.FinalizeRunContext` <- function(contextname) {
  invisible(rcompss_finalize_context(contextname))
}

# ---- GPU memory (allocated in R) ----

#' Allocate GPU buffer from R (number of double elements).
#' Returns an external pointer handle. Free with RCOMPSs.GpuFree or by GC.
#' Active context must be GPU.
#' @param n Number of double elements.
#' @return External pointer (GPU buffer handle).
#' @export
`RCOMPSs.GpuAlloc` <- function(n) {
  rcompss_gpu_alloc(n)
}

#' Copy R numeric vector to GPU buffer (host to device).
#' @param r_vec Numeric vector (host).
#' @param gpu_handle Handle from RCOMPSs.GpuAlloc(n); length(r_vec) must be <= n.
#' @export
`RCOMPSs.CopyToGpu` <- function(r_vec, gpu_handle) {
  invisible(rcompss_copy_to_gpu(r_vec, gpu_handle))
}

#' Copy GPU buffer to R (device to host). Returns a new numeric vector.
#' @param gpu_handle Handle from RCOMPSs.GpuAlloc(n).
#' @return Numeric vector of length n.
#' @export
`RCOMPSs.CopyFromGpu` <- function(gpu_handle) {
  rcompss_copy_from_gpu(gpu_handle)
}

#' Free GPU buffer. Safe to call multiple times; handle is invalidated.
#' @param gpu_handle Handle from RCOMPSs.GpuAlloc.
#' @export
`RCOMPSs.GpuFree` <- function(gpu_handle) {
  invisible(rcompss_gpu_free(gpu_handle))
}

#' Run vector addition kernel only (inputs and output are GPU buffers from R).
#' result = a + b element-wise; all three handles must be from RCOMPSs.GpuAlloc with same length.
#' @param d_a_handle GPU buffer handle (first vector).
#' @param d_b_handle GPU buffer handle (second vector).
#' @param d_result_handle GPU buffer handle (output).
#' @export
`RCOMPSs.GpuVectorAddKernel` <- function(d_a_handle, d_b_handle, d_result_handle) {
  invisible(rcompss_gpu_vector_add_kernel(d_a_handle, d_b_handle, d_result_handle))
}
