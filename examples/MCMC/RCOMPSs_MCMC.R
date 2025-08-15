# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

# @file RCOMPSs_MCMC.R
# @brief This file contains the main application
# @version 1.0
# @author Xiran Zhang
# @date 2025-08-07

use_RCOMPSs <- TRUE 
source("settings.R")
source("task_MCMC.R")

if(use_RCOMPSs) {
  library(RCOMPSs)
  compss_start()
  mc.dec <- task(mcmc_metropolis, "task_MCMC.R", info_only = FALSE, return_value = TRUE)
}

for(j in 1:5){
  chains <- list()
  tic()
  if(use_RCOMPSs) {
    for(i in 1:n_chains) {
      # Task for each chain
      chains[[i]] <- mc.dec(MCinput)
    }
    chains <- compss_wait_on(chains)
  } else {
    # Fallback to sequential execution if RCOMPSs is not used
    for(i in 1:n_chains) {
      chains[[i]] <- mcmc_metropolis(MCinput)
    }
  }
  toc(n_samples, n_iter, "RCOMPSs", j)
}

# Combine results
all_samples <- do.call(c, chains)

# Plot the results
#MCplot(all_samples, true_mean, "RCOMPSs")

if(use_RCOMPSs) {
  compss_stop()
}
