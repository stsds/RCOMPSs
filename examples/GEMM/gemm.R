library(RCOMPSs)
source("blkmm.R")

m1 <- 2000
m2 <- 2000
m3 <- 2000
n1 <- 6000
n2 <- 6000
n3 <- 6000

nb1 <- n1 %/% m1
nb2 <- n2 %/% m2
nb3 <- n3 %/% m3

get_index <- function(k, tile_size, dimension){
  if(k * tile_size <= dimension){
    return( ( (k-1)*tile_size+1 ):(k*tile_size) )
  }else if((k-1)*tile_size+1 <= dimension){
    return( ( (k-1)*tile_size+1 ):dimension )
  }else{
    cat("Row index out of bound!")
  }
}

set.seed(1)
A <- matrix(runif(n = n1*n2), nrow = n1, ncol = n2)
B <- matrix(runif(n = n2*n3), nrow = n2, ncol = n3)

TIME.R <- proc.time()
D1 <- A %*% B
TIME.R <- proc.time() - TIME.R

TIME.RCOMPSs <- proc.time()
D2 <- matrix(0, nrow = n1, ncol = n3)
T1 <- list()

compss_start()

mm <- task(multiplication, "blkmm.R", info_only = FALSE, return_value = TRUE)
add <- task(addition, "blkmm.R", info_only = FALSE, return_value = TRUE)

for(i in 1:nb1){
  for(k in 1:nb3){
    T1[[(i-1) + (k-1) * nb1 + 1]] <- D2[get_index(i, m1, n1), get_index(k, m3, n3)]
    for(j in 1:nb2){
      K1 <-  A[get_index(i, m1, n1), get_index(j, m2, n2)]
      K2 <-  B[get_index(j, m2, n2), get_index(k, m3, n3)]
      T2 <- mm(K1, K2)
      T3 <- T1[[(i-1) + (k-1) * nb1 + 1]]
      T1[[(i-1) + (k-1) * nb1 + 1]] <- add(T3, T2)
    }
  }
}
for(i in 1:nb1){
  for(k in 1:nb3){
    t1 <- compss_wait_on(T1[[(i-1) + (k-1) * nb1 + 1]])
    D2[get_index(i, m1, n1), get_index(k, m3, n3)] <- t1
  }
}
TIME.RCOMPSs <- proc.time() - TIME.RCOMPSs

cat("****************************************\n")
cat("The norm of the difference matrix is:", norm(D1 - D2, "F"), "\n")
cat("Time for R is", TIME.R[3], "seconds\n")
cat("Time for RCOMPSs is", TIME.RCOMPSs[3], "seconds\n")
cat("****************************************\n")
compss_stop()
