# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

# @file job.R
# @brief This file contains the main application
# @version 1.0
# @author Xiran Zhang
# @date 2025-04-28

library(RCOMPSs)
source("add.R")
compss_start()
add.dec <- task(add, "add.R", info_only = FALSE, return_value = TRUE)
a <- 4; b <- 5; c <- 6; d <- 7
# Task (1)
res1 <- add.dec(a, b)
# Task (2)
res2 <- add.dec(c, d)
# Task (3)
res3 <- add.dec(res1, res2)
res3 <- compss_wait_on(res3)
cat("The result is:", res3, "\n")
compss_stop()
