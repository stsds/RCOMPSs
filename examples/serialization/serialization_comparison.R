# Serialization of matrices
# setwd("/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/RCOMPSs/examples/serialization")
Rcpp::sourceCpp("../IO/BinaryOutput.cpp")

# dim_range <- c(10, 1e2, 5e2, 1e3, 2e3, 3e3, 4e3, 5e3, 6e3, 7e3)
dim_range <- c(1e2, 5e2, 1e3, 5e3, 1e4, 2e4, 3e4)
dim_range <- 2e4
time <- data.frame(ser_time = numeric(0),
                   unser_time = numeric(0),
                   block_size = numeric(0),
                   difference = numeric(0),
                   method = character(0))

methods_to_evaluate <- c("serialize", "RDS", "fst", "qs", "RMVL")
methods_to_evaluate <- c("qs", "RMVL")

k <- 1
for(i in 1:length(dim_range)){#:length(dim_range)

  cat("The dimension is:", dim_range[i], "\n")
  A <- matrix(rnorm(dim_range[i]^2), nrow = dim_range[i], ncol = dim_range[i])

  # serialize
  if("serialize" %in% methods_to_evaluate){
    cat("serialize():", "\n")
    SER.TIME <- proc.time()
    PURE.SER.TIME <- proc.time()
    x <- serialize(object = A, connection = NULL)
    PURE.SER.TIME <- proc.time() - PURE.SER.TIME
    WRITING.TIME <- proc.time()
    WriteBinary(x, filename = "./serialize_Rcpp")
    WRITING.TIME <- proc.time() - WRITING.TIME
    SER.TIME <- proc.time() - SER.TIME
    cat("Serialization time:", SER.TIME[3], "seconds\n")
    cat("Pure serialization time:", PURE.SER.TIME[3], "seconds\n")
    cat("Writing time:", WRITING.TIME[3], "seconds\n")
    UNSER.TIME <- proc.time()
    READING.TIME <- proc.time()
    y <- ReadBinary(filename = "./serialize_Rcpp", size = file.info("./serialize_Rcpp")$size)
    READING.TIME <- proc.time() - READING.TIME
    PURE.UNSER.TIME <- proc.time()
    A1 <- unserialize(connection = y)
    PURE.UNSER.TIME <- proc.time() - PURE.UNSER.TIME
    UNSER.TIME <- proc.time() - UNSER.TIME
    cat("Unserialization time:", UNSER.TIME[3], "seconds\n")
    cat("Pure unserialization time:", PURE.UNSER.TIME[3], "seconds\n")
    cat("Reading time:", READING.TIME[3], "seconds\n")
    time[k,1:3] <- c(SER.TIME[3], UNSER.TIME[3], dim_range[i])
    time[k,4] <- sum(abs(A - A1))
    time[k,5] <- "serialize_Rcpp"
    k <- k + 1
    file.remove("./serialize_Rcpp")
    cat("\n")
  }

  # RDS
  if("RDS" %in% methods_to_evaluate){
    cat("RDS:", "\n")
    SER.TIME <- proc.time()
    saveRDS(object = A, file = "./RDS")
    SER.TIME <- proc.time() - SER.TIME
    cat("Serialization time:", SER.TIME[3], "seconds\n")
    UNSER.TIME <- proc.time()
    A1 <- readRDS(file = "./RDS")
    UNSER.TIME <- proc.time() - UNSER.TIME
    cat("Unserialization time:", UNSER.TIME[3], "seconds\n")
    time[k,1:3] <- c(SER.TIME[3], UNSER.TIME[3], dim_range[i])
    time[k,4] <- sum(abs(A - A1))
    time[k,5] <- "RDS"
    k <- k + 1
    file.remove("./RDS")
    cat("\n")
  }

  # fst
  if("fst" %in% methods_to_evaluate){
    cat("fst:", "\n")
    SER.TIME <- proc.time()
    fst::write.fst(as.data.frame(A), path = "./fst", compress = 0)
    SER.TIME <- proc.time() - SER.TIME
    cat("Serialization time:", SER.TIME[3], "seconds\n")
    UNSER.TIME <- proc.time()
    A1 <- as.matrix(fst::read.fst(path = "./fst"))
    UNSER.TIME <- proc.time() - UNSER.TIME
    cat("Unserialization time:", UNSER.TIME[3], "seconds\n")
    time[k,1:3] <- c(SER.TIME[3], UNSER.TIME[3], dim_range[i])
    time[k,4] <- sum(abs(A - A1))
    time[k,5] <- "fst"
    k <- k + 1
    file.remove("./fst")
    cat("\n")
  }
  
  # qs
  if("qs" %in% methods_to_evaluate){
    cat("qs:", "\n")
    SER.TIME <- proc.time()
    qs::qsave(A, file = "./qs", preset = "uncompressed")
    SER.TIME <- proc.time() - SER.TIME
    cat("Serialization time:", SER.TIME[3], "seconds\n")
    UNSER.TIME <- proc.time()
    A1 <- qs::qread(file = "./qs", nthreads = 50)
    UNSER.TIME <- proc.time() - UNSER.TIME
    cat("Unserialization time:", UNSER.TIME[3], "seconds\n")
    time[k,1:3] <- c(SER.TIME[3], UNSER.TIME[3], dim_range[i])
    time[k,4] <- sum(abs(A - A1))
    time[k,5] <- "qs"
    k <- k + 1
    file.remove("./qs")
    cat("\n")
  }

  # RMVL
  if("RMVL" %in% methods_to_evaluate){
    cat("RMVL:", "\n")
    SER.TIME <- proc.time()
    con <- RMVL::mvl_open("./RMVL.mvl", append = TRUE, create = TRUE)
    RMVL::mvl_write_object(con, A, name = "A")
    RMVL::mvl_close(con)
    SER.TIME <- proc.time() - SER.TIME
    cat("Serialization time:", SER.TIME[3], "seconds\n")
    UNSER.TIME <- proc.time()
    A2 <- RMVL::mvl_open("./RMVL.mvl")
    A3 <- RMVL::mvl2R(A2$A)
    RMVL::mvl_close(con)
    UNSER.TIME <- proc.time() - UNSER.TIME
    cat("Unserialization time:", UNSER.TIME[3], "seconds\n")
    time[k,1:3] <- c(SER.TIME[3], UNSER.TIME[3], dim_range[i])
    time[k,4] <- sum(abs(A - A3))
    time[k,5] <- "RMVL"
    k <- k + 1
    file.remove("./RMVL.mvl")
    cat("\n")
  }

  write.table(time, file = "time.csv", row.names = FALSE, sep = ",")
}

# library(ggplot2)
# pdf("time.pdf")
#  ggplot(data = time, mapping = aes(x = block_size, y = ser_time + unser_time, color = method)) +
#   geom_point() +
#  geom_line() +
#  labs(title = "Serialization time", x = "Matrix dimension", y = "Time(s)") +
#  theme_minimal()
# dev.off()
