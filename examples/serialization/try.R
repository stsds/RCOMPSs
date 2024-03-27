# Serialization of matrices

dim_range <- c(10, 1e2, 5e2, 1e3, 2e3, 3e3, 4e3, 5e3, 6e3, 7e3)
time <- data.frame(ser_time = numeric(0),
                   unser_time = numeric(0),
                   block_size = numeric(0),
                   method = character(0))

k <- 1
for(i in 1:length(dim_range)){#:length(dim_range)
 
  cat("The dimension is:", dim_range[i], "\n")
  A <- matrix(rnorm(dim_range[i]^2), nrow = dim_range[i], ncol = dim_range[i])

  # serialize
  cat("serialize():", "\n")
  SER.TIME <- proc.time()
  con <- file(description = "./serialize", open = "wb")
  #serialize(object = A, connection = con)
  x <- serialize(object = A, connection = NULL)
  writeBin(x, con)
  close(con)
  SER.TIME <- proc.time() - SER.TIME
  cat("Serialize:", SER.TIME[3], "seconds\n")
  UNSER.TIME <- proc.time()
  con <- file(description = "./serialize", open = "rb")
  y <- readBin(con, what = raw(), n = file.info("./serialize")$size)
  A1 <- unserialize(connection = y)
  close(con)
  UNSER.TIME <- proc.time() - UNSER.TIME
  time[k,1:3] <- c(SER.TIME[3], UNSER.TIME[3], dim_range[i])
  time[k,4] <- "serialize"
  k <- k + 1

  # RDS
  # cat("RDS:", "\n")
  # SER.TIME <- proc.time()
  # saveRDS(object = A, file = "./RDS")
  # SER.TIME <- proc.time() - SER.TIME
  # UNSER.TIME <- proc.time()
  # A2 <- readRDS(file = "./RDS")
  # UNSER.TIME <- proc.time() - UNSER.TIME
  # time[k,1:3] <- c(SER.TIME[3], UNSER.TIME[3], dim_range[i])
  # time[k,4] <- "RDS"
  # k <- k + 1
  
  # fst
  # cat("fst:", "\n")
  # SER.TIME <- proc.time()
  # fst::write_fst(as.data.frame(A), path = "./fst", compress = 0)
  # SER.TIME <- proc.time() - SER.TIME
  # UNSER.TIME <- proc.time()
  # A3 <- fst::read.fst(path = "./fst")
  # UNSER.TIME <- proc.time() - UNSER.TIME
  # time[k,1:3] <- c(SER.TIME[3], UNSER.TIME[3], dim_range[i])
  # time[k,4] <- "fst"
  # k <- k + 1

  write.csv(time, file = "time.csv")
}
