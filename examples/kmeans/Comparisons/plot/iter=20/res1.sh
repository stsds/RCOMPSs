#!/bin/bash

iterations=20
replicate=5
seed=123

for n_sample in $(seq 200000 2200000 17800000); do

    echo "parallel"
    Rscript parallel_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates $replicate --arity 50 --workers 50 --seed $seed
    sleep 5

    echo "future.apply"
    Rscript future_apply_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates $replicate --arity 50 --plan multicore --workers 50 --seed $seed
    sleep 5

    echo "furrr"
    Rscript furrr_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates $replicate --arity 50 --plan multicore --workers 50 --seed $seed
    sleep 5
    
    echo "future"
    Rscript future_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates $replicate --arity 50 --plan multicore --workers 50 --seed $seed
    sleep 5
    
    cd ..
    echo "Sequential"
    compss_clean_procs
    sleep 1
    runcompss --lang=r --cpu_affinity=disabled kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates $replicate --arity 50 --plot FALSE --seed $seed
    echo "RCOMPSs"
    compss_clean_procs
    sleep 2
    runcompss --lang=r --cpu_affinity=disabled kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates $replicate --arity 50 --plot FALSE --RCOMPSs --seed $seed
    compss_clean_procs
    sleep 5
    cd Comparisons
done
