library(RCOMPSs)
source("add3.R")
compss_start()
dec <- task(add_three, "add3", info_only = FALSE, return_value = TRUE)
a <- 5
b <- 4
res <- dec(a, b)
res <- compss_wait_on(res)
cat("The results is:", res)
compss_stop()
