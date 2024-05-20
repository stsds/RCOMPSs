# I/O operations comparison
setwd("/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/RCOMPSs/examples/IO")
Rcpp::sourceCpp("BinaryOutput.cpp")

dim_range <- c(1e2, 5e2, 1e3, 5e3, 1e4, 2e4, 3e4)
# dim_range <- 1e4
time <- data.frame(write_time = numeric(0),
                   read_time = numeric(0),
                   length = numeric(0),
                   difference = numeric(0),
                   method = character(0))

methods_to_evaluate <- c("writeBin_readBin", "save_load", "data.table::fread_fwrite", "readr::write_file_read_file_raw", "Rcpp")
methods_to_evaluate <- c("writeBin_readBin", "data.table::fread_fwrite", "readr::write_file_read_file_raw", "Rcpp")
# methods_to_evaluate <- c("writeBin_readBin", "Rcpp")
# methods_to_evaluate <- c("Rcpp")

k <- 1
for(i in 1:length(dim_range)){#:length(dim_range)

  cat("The dimension is:", dim_range[i], "\n")
  A <- matrix(rnorm(dim_range[i]^2), nrow = dim_range[i], ncol = dim_range[i])
  x <- serialize(object = A, connection = NULL)

  # writeBin_readBin
  if("writeBin_readBin" %in% methods_to_evaluate){
    cat("writeBin_readBin:", "\n")
    WRITING.TIME <- proc.time()
    writeBin(x, con = "./ser")
    WRITING.TIME <- proc.time() - WRITING.TIME
    
    READING.TIME <- proc.time()
    A1 <- readBin(con = "./ser", what = raw(), n = file.info("./ser")$size)
    READING.TIME <- proc.time() - READING.TIME
    
    cat("Writing time:", WRITING.TIME[3], "seconds\n")
    cat("Reading time:", READING.TIME[3], "seconds\n")
    diff <- sum(abs(A - unserialize(A1)))
    cat("Difference:", diff, "\n")

    time[k,1:4] <- c(WRITING.TIME[3], READING.TIME[3], dim_range[i]^2, diff)
    time[k,5] <- "writeBin_readBin"
    k <- k + 1
    file.remove("./ser")
    cat("\n")
  }
  
  # save_load
  if("save_load" %in% methods_to_evaluate){
    cat("save_load:", "\n")
    WRITING.TIME <- proc.time()
    save(x, file = "./ser.RData")
    WRITING.TIME <- proc.time() - WRITING.TIME
    
    READING.TIME <- proc.time()
    load(file = "./ser.RData")
    READING.TIME <- proc.time() - READING.TIME
    
    cat("Writing time:", WRITING.TIME[3], "seconds\n")
    cat("Reading time:", READING.TIME[3], "seconds\n")
    diff <- sum(abs(A - unserialize(x)))
    cat("Difference:", diff, "\n")
    
    time[k,1:4] <- c(WRITING.TIME[3], READING.TIME[3], dim_range[i]^2, diff)
    time[k,5] <- "save_load"
    k <- k + 1
    file.remove("./ser.RData")
    cat("\n")
  }

  # fread_fwrite
  if("data.table::fread_fwrite" %in% methods_to_evaluate){
    cat("data.table::fread_fwrite:", "\n")
    WRITING.TIME <- proc.time()
    data.table::fwrite(A, file = "./ser_fwrite.csv", row.names = FALSE, col.names = FALSE)
    WRITING.TIME <- proc.time() - WRITING.TIME
    
    READING.TIME <- proc.time()
    A1 <- data.table::fread(file = "./ser_fwrite.csv", header = FALSE)
    READING.TIME <- proc.time() - READING.TIME
    
    cat("Writing time:", WRITING.TIME[3], "seconds\n")
    cat("Reading time:", READING.TIME[3], "seconds\n")
    diff <- sum(abs(A - A1))
    cat("Difference:", diff, "\n")
    
    time[k,1:4] <- c(WRITING.TIME[3], READING.TIME[3], dim_range[i]^2, diff)
    time[k,5] <- "data.table::fread_fwrite"
    k <- k + 1
    file.remove("./ser_fwrite.csv")
    cat("\n")
  }
  
  # readr::write_file_read_file_raw
  if("readr::write_file_read_file_raw" %in% methods_to_evaluate){
    cat("readr::write_file_read_file_raw:", "\n")
    WRITING.TIME <- proc.time()
    readr::write_file(x, file = "./readr")
    WRITING.TIME <- proc.time() - WRITING.TIME
    
    READING.TIME <- proc.time()
    A1 <- readr::read_file_raw(file = "./readr")
    READING.TIME <- proc.time() - READING.TIME
    
    cat("Writing time:", WRITING.TIME[3], "seconds\n")
    cat("Reading time:", READING.TIME[3], "seconds\n")
    diff <- sum(abs(A - unserialize(A1)))
    cat("Difference:", diff, "\n")
    
    time[k,1:4] <- c(WRITING.TIME[3], READING.TIME[3], dim_range[i]^2, diff)
    time[k,5] <- "readr::write_file_read_file_raw"
    k <- k + 1
    file.remove("./readr")
    cat("\n")
  }
  
  # Rcpp
  if("Rcpp" %in% methods_to_evaluate){
    cat("Rcpp:", "\n")
    WRITING.TIME <- proc.time()
    WriteBinary(x, filename = "./Rcpp")
    WRITING.TIME <- proc.time() - WRITING.TIME
    
    READING.TIME <- proc.time()
    A1 <- ReadBinary(filename = "./Rcpp", size = file.info("./Rcpp")$size)
    READING.TIME <- proc.time() - READING.TIME
    
    cat("Writing time:", WRITING.TIME[3], "seconds\n")
    cat("Reading time:", READING.TIME[3], "seconds\n")
    diff <- sum(abs(A - unserialize(A1)))
    cat("Difference:", diff, "\n")

    time[k,1:4] <- c(WRITING.TIME[3], READING.TIME[3], dim_range[i]^2, diff)
    time[k,5] <- "Rcpp"
    k <- k + 1
    file.remove("./Rcpp")
    cat("\n")
  }
}

write.csv(time, file = "./time.csv", row.names = FALSE)

# library(ggplot2)
# pdf("time.pdf")
#  ggplot(data = time, mapping = aes(x = block_size, y = ser_time + unser_time, color = method)) +
#   geom_point() +
#  geom_line() +
#  labs(title = "Serialization time", x = "Matrix dimension", y = "Time(s)") +
#  theme_minimal()
# dev.off()
