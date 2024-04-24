print(sessionInfo())
m <- 25000
n <- m^2
cat("Generating matrices ... ")
A <- matrix(runif(n), ncol = m)
B <- matrix(runif(n), ncol = m)
cat("Done.\n")

cat("Matrix multiplication ... ")
C <- A %*% B
cat("Done.\n")

cat("Serializing ... ")
con <- file(description = "./ser", open = "wb")
x <- serialize(object = C, connection = NULL)
writeBin(x, con)
close(con)
cat("Done.\n")
