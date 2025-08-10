# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

# @file parallel_MCMC.R
# @brief This file contains the main application
# @version 1.0
# @author Xiran Zhang
# @date 2025-08-07

library(parallel)

source("settings.R")
source("task_MCMC.R")

# Use mclapply for parallel processing
for(j in 1:2) {
  tic()
  chains <- mclapply(1:n_chains, function(x) {
    mcmc_metropolis(MCinput)
  }, mc.cores = n_chains)
  toc(paste0("PARALLEL_", j))
}

# Combine results
all_samples <- do.call(c, chains)

# Plot the results
MCplot(all_samples, true_mean, "parallel")