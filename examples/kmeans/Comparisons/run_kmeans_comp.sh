#!/bin/bash

#for n_sample in $(seq 200000 2200000 20000000); do
#for n_sample in $(seq 15600000 2200000 20000000); do
for n_sample in $(seq 17800000 2200000 17800000); do

    # Run each kmeans script
    # Rscript parallel_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations 2 --arity 50 --workers 50
    # sleep 5
    # Rscript future_apply_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations 2 --arity 50 --plan multicore --workers 50
    # sleep 5
    # Rscript furrr_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations 2 --arity 50 --plan multicore --workers 50
    # sleep 5
    # cd ..
    # compss_clean_procs
    # sleep 5
    # runcompss --lang=r --cpu_affinity=disabled kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations 2 --arity 50 --plot FALSE --RCOMPSs
    # sleep 5
    # cd Comparisons

    Rscript future_bigmemory_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations 2 --arity 50 --plan multicore --workers 50
    #compss_clean_procs
    #cd ..
    #sleep 1
    #runcompss --lang=r --cpu_affinity=disabled kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations 2 --arity 50 --plot FALSE
    sleep 3
    #cd Comparisons
done
