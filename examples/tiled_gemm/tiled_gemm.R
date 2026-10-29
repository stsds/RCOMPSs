# Source after library(RCOMPSs). Call compss_start() before registering tasks.
register_tiled_gemm <- function(mode = c("CPU", "GPU"), filename = "tasks.R") {
  mode <- match.arg(mode)
  source(filename, local = TRUE)
  if (mode == "CPU") {
    task(tile_gemm_cpu, filename, return_value = TRUE)
  } else {
    constrained <- constraint(tile_gemm_gpu, processors = list(
      list(processorType = "CPU", computingUnits = "1"),
      list(processorType = "GPU", computingUnits = "1")))
    task(constrained, filename, return_value = TRUE)
  }
}

tiled_gemm <- function(A, B, C = NULL, tile = 512L, alpha = 1, beta = 0,
                       update_task) {
  stopifnot(is.matrix(A), is.double(A), is.matrix(B), is.double(B),
            ncol(A) == nrow(B), all(dim(A) > 0), all(dim(B) > 0),
            length(tile) == 1, is.finite(tile), tile >= 1, tile == floor(tile),
            length(alpha) == 1, is.finite(alpha), length(beta) == 1, is.finite(beta))
  if (is.null(C)) C <- matrix(0, nrow(A), ncol(B))
  stopifnot(is.matrix(C), is.double(C), identical(dim(C), c(nrow(A), ncol(B))))
  partition <- function(n) split(seq_len(n), (seq_len(n) - 1L) %/% tile)
  ii <- partition(nrow(A)); jj <- partition(ncol(B)); kk <- partition(ncol(A))
  # Partition before the operation timer, just as DPLASMA starts from tiled data.
  at <- lapply(ii, function(i) lapply(kk, function(k) A[i, k, drop = FALSE]))
  bt <- lapply(kk, function(k) lapply(jj, function(j) B[k, j, drop = FALSE]))
  ct <- lapply(ii, function(i) lapply(jj, function(j) C[i, j, drop = FALSE]))
  start <- proc.time()[["elapsed"]]
  for (k in seq_along(kk)) for (i in seq_along(ii)) for (j in seq_along(jj)) {
    ct[[i]][[j]] <- update_task(at[[i]][[k]], bt[[k]][[j]], ct[[i]][[j]],
                              alpha, if (k == 1L) beta else 1)
  }
  submitted <- proc.time()[["elapsed"]]
  # Wait only after the DAG is submitted; successive updates depend on C futures.
  for (i in seq_along(ii)) for (j in seq_along(jj)) {
    C[ii[[i]], jj[[j]]] <- compss_wait_on(ct[[i]][[j]])
  }
  finish <- proc.time()[["elapsed"]]
  list(C = C, seconds = finish - start, submission_seconds = submitted - start,
       tasks = length(ii) * length(jj) * length(kk))
}
