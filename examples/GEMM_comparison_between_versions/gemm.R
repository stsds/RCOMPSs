a <- sessionInfo()

#for( m in rep(seq(1000, 10000, 2000), each = 5) ){
for(m in c(2e4, 3e4)){
  n <- m^2
  cat("Generating matrices ... ")
  A <- matrix(runif(n), ncol = m)
  B <- matrix(runif(n), ncol = m)
  cat("Done.\n")

  cat("Matrix multiplication ... ")
  TIME.R <- proc.time()[3]
  C <- A %*% B
  TIME.R <- proc.time()[3] - TIME.R
  cat("Done.\n")
  write.table(data.frame(TIME.R, paste0(a$R.version$major, ".", a$R.version$minor), m), append = TRUE,
              "time_gemm.csv", sep = ",", row.names = FALSE, col.names = FALSE)
}
