a <- sessionInfo()

#for( m in rep(seq(1000, 9000, 2000), each = 5) ){
for( m in rep(seq(11000, 39000, 2000), each = 5) ){
  n <- m^2
  cat("Generating covariance matrix ... ")
  A <- matrix(runif(n), ncol = m)
  C <- t(A) %*% A
  cat("Done.\n")

  cat("Cholesky decomposition ... ")
  TIME.R <- proc.time()[3]
  C <- chol(C)
  TIME.R <- proc.time()[3] - TIME.R
  cat("Done.\n")
  write.table(data.frame(TIME.R, paste0(a$R.version$major, ".", a$R.version$minor), m), append = TRUE,
              "time_chol.csv", sep = ",", row.names = FALSE, col.names = FALSE)
}
