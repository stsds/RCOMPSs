library(RCOMPSs)
source("blkmm.R")
compss_start()

dimension.range <- seq(1000, 9000, 2000)
res <- as.data.frame(matrix(nrow = 0, ncol = 4))
colnames(res) <- c("time(s)", "method", "dimension", "tile_size")

mm <- task(multiplication, "blkmm.R", info_only = FALSE, return_value = TRUE)
add <- task(addition, "blkmm.R", info_only = FALSE, return_value = TRUE)

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

for(dimension in dimension.range){

  n1 <- dimension
  n2 <- dimension
  n3 <- dimension

  cat("Current dimension is:", dimension, "\n")

  A <- matrix(runif(n = n1*n2), nrow = n1, ncol = n2)
  B <- matrix(runif(n = n2*n3), nrow = n2, ncol = n3)

  cat("R multiplication ... ")
  TIME.R <- proc.time()
  D1 <- A %*% B
  TIME.R <- proc.time() - TIME.R
  cat("Done.\n")
  flush.console()

  res <- rbind(res, c(TIME.R[3], "R", dimension, NA))
  write.table(data.frame(TIME.R[3], "R", dimension, NA), append = TRUE,
                "time.csv", sep = ",", row.names = FALSE, col.names = FALSE)

  if(dimension == 1000){
    ts.range <- c(100, seq(100, dimension/2, 100))
  }else{
    ts.range <- c(4200, 4300, 4400, 4500) # seq(dimension/10, dimension/2, 100)
  }

  for(ts in ts.range){

    m1 <- ts
    m2 <- ts
    m3 <- ts

    nb1 <- n1 %/% m1
    nb2 <- n2 %/% m2
    nb3 <- n3 %/% m3

    TIME.RCOMPSs <- proc.time()
    D2 <- matrix(0, nrow = n1, ncol = n3)
    T1 <- list()

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
    cat("Tile size is", ts, "\n")
    cat("****************************************\n")
    flush.console()

    res <- rbind(res, c(TIME.RCOMPSs[3], "RCOMPSs", dimension, ts))

    write.table(data.frame(TIME.RCOMPSs[3], "RCOMPSs", dimension, ts), append = TRUE,
                "time.csv", sep = ",", row.names = FALSE, col.names = FALSE)
  }
}

#res[,1] <- as.numeric(res[,1])
#res[,3] <- as.numeric(res[,3])
#res[,4] <- as.numeric(res[,4])

#write.table(res, "time.csv", sep = ",", row.names = FALSE, col.names = FALSE)

compss_stop()
