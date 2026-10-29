# Source after library(RCOMPSs). Call compss_start() before registering tasks.
register_tiled_gemm <- function(mode = c("CPU", "GPU"), filename = "tasks.R") {
  mode <- match.arg(mode)
  source(filename, local = TRUE)
  if (mode == "CPU") {
    task(tile_gemm_cpu_reduce, filename, return_value = TRUE)
  } else {
    constrained <- constraint(tile_gemm_gpu_reduce, processors = list(
      list(processorType = "CPU", computingUnits = "1"),
      list(processorType = "GPU", computingUnits = "1")))
    task(constrained, filename, return_value = TRUE)
  }
}

tiled_gemm <- function(A, B, C = NULL, tile = 512L, alpha = 1, beta = 0,
                       update_task, column_group = 1L, row_group = 1L) {
  stopifnot(is.matrix(A), is.double(A), is.matrix(B), is.double(B),
            ncol(A) == nrow(B), all(dim(A) > 0), all(dim(B) > 0),
            length(tile) == 1, is.finite(tile), tile >= 1, tile == floor(tile),
            length(row_group) == 1, is.finite(row_group),
            row_group >= 1, row_group == floor(row_group),
            length(column_group) == 1, is.finite(column_group),
            column_group >= 1, column_group == floor(column_group),
            length(alpha) == 1, is.finite(alpha), length(beta) == 1, is.finite(beta))
  if (is.null(C)) C <- matrix(0, nrow(A), ncol(B))
  stopifnot(is.matrix(C), is.double(C), identical(dim(C), c(nrow(A), ncol(B))))
  partition <- function(n, block = tile) split(seq_len(n), (seq_len(n) - 1L) %/% block)
  ii <- partition(nrow(A), tile * row_group); jj <- partition(ncol(B), tile * column_group); kk <- partition(ncol(A))
  # Partition before the operation timer, just as DPLASMA starts from tiled data.
  at <- lapply(ii, function(i) lapply(kk, function(k) A[i, k, drop = FALSE]))
  bt <- lapply(kk, function(k) lapply(jj, function(j) B[k, j, drop = FALSE]))
  ct <- lapply(ii, function(i) lapply(jj, function(j) C[i, j, drop = FALSE]))
  # Group tile references before timing; serializing the panels is timed.
  bp <- lapply(seq_along(jj), function(j) lapply(bt, function(row) row[[j]]))
  start <- proc.time()[["elapsed"]]
  for (i in seq_along(ii)) for (j in seq_along(jj)) {
    ct[[i]][[j]] <- update_task(at[[i]], bp[[j]], ct[[i]][[j]], alpha, beta)
  }
  submitted <- proc.time()[["elapsed"]]
  # Each future owns an entire output-tile reduction; collect after submission.
  for (i in seq_along(ii)) for (j in seq_along(jj)) {
    C[ii[[i]], jj[[j]]] <- compss_wait_on(ct[[i]][[j]])
  }
  finish <- proc.time()[["elapsed"]]
  list(C = C, seconds = finish - start, submission_seconds = submitted - start,
       tasks = length(ii) * length(jj),
       tile_updates = length(ii) * length(jj) * length(kk))
}
