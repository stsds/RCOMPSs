# This file explores the time for matrix-matrix multiplication in R
# The output file time.csv contains two columns, tile size and the corresponding time

ts.range <- seq(100, 2000, 100)
print(ts.range)

res <- as.data.frame(matrix(nrow = 0, ncol = 2))
for(ts in ts.range){
  A <- matrix(rnorm(ts*ts), nrow = ts, ncol = ts)
  B <- matrix(rnorm(ts*ts), nrow = ts, ncol = ts)
  TIME.R <- proc.time()
  C <- A %*% B
  TIME.R <- proc.time() - TIME.R
  res <- rbind(res, c(ts, TIME.R[3]))
}

write.table(res, "time.csv", sep = ",", row.names = FALSE, col.names = FALSE)
