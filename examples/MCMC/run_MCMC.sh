#!/bin/bash

# Experiment to run parallel_MCMC.R, future_MCMC.R and RCOMPSs_MCMC.R with different problem sizes from 1e4 to 1e5 by 1e4
for n_sample in $(seq 10000 10000 100000); do
  sed -i "s/n_samples <- .*/n_samples <- $n_sample/" settings.R
  for n_iter in $(seq 10000 10000 100000); do
    # Update the settings.R file with the new problem size
    sed -i "s/n_iter <- .*/n_iter <- $n_iter/" settings.R

    # Run each MCMC script
    # Output stored in file output.txt
    Rscript parallel_MCMC.R #>> output.txt
    sleep 2
    Rscript future_MCMC.R #>> output.txt
    sleep 2
    compss_clean_procs
    sleep 2
    runcompss --lang=r --cpu_affinity=disabled RCOMPSs_MCMC.R #>> output.txt
    sleep 2
  done
done
