library(RCOMPSs)
source("tiled_gemm.R")
mode <- Sys.getenv("GEMM_MODE", "CPU")
output <- Sys.getenv("GEMM_OUTPUT", paste0("results-", mode, ".csv"))
compss_start()
main <- function() {
 on.exit(compss_stop(), add = TRUE)
 update <- register_tiled_gemm(mode)
 set.seed(20261029)
 # Untimed correctness tests: scalar, rectangular/ragged edges, and general alpha/beta.
 for (d in list(c(1L,1L,1L,1L), c(65L,49L,33L,32L), c(32L,64L,16L,32L))) {
  A <- matrix(runif(d[1]*d[2])-.5,d[1],d[2]);B <- matrix(runif(d[2]*d[3])-.5,d[2],d[3])
  C <- matrix(runif(d[1]*d[3])-.5,d[1],d[3])
  z <- tiled_gemm(A,B,C,d[4],.51,-.42,update)
  ref <- .51*(A%*%B)-.42*C
  error <- sqrt(sum((z$C-ref)^2))/max(1,sqrt(sum(ref^2)))
  stopifnot(identical(dim(z$C),dim(ref)), error < 1e-12)
  cat("CORRECT",mode,paste(d,collapse="x"),error,"\n")
  if (d[1] == 65L) {
   z0 <- tiled_gemm(A,B,tile=d[4],update_task=update)
   stopifnot(max(abs(z0$C-A%*%B)) < 1e-12)
   z1 <- tiled_gemm(A,B,C,d[4],0,1,update)
   stopifnot(identical(z1$C,C))
   cat("CORRECT",mode,"default alpha/beta and alpha=0 beta=1\n")
  }
 }
 cases <- read.csv(Sys.getenv("GEMM_CASES", "cases.csv"))
 rows <- list()
 for (q in seq_len(nrow(cases))) {
  n <- cases$n[q]; tile <- cases$tile[q]
  A <- matrix(runif(n*n)-.5,n,n);B <- matrix(runif(n*n)-.5,n,n);C <- matrix(runif(n*n)-.5,n,n)
  ref <- .51*(A%*%B)-.42*C
  for (trial in 0:3) {
   gc()
   z <- tiled_gemm(A,B,C,tile,.51,-.42,update)
   error <- sqrt(sum((z$C-ref)^2))/sqrt(sum(ref^2))
   stopifnot(error < 1e-12)
   row <- data.frame(runtime="RCOMPSs",mode=mode,n=n,tile=tile,trial=trial,
                     seconds=z$seconds,submission_seconds=z$submission_seconds,
                     tasks=z$tasks,gflops=2*n^3/z$seconds/1e9,relative_error=error)
   print(row);rows[[length(rows)+1L]] <- row
   write.csv(do.call(rbind,rows),output,row.names=FALSE)
  }
 }
}
main()
