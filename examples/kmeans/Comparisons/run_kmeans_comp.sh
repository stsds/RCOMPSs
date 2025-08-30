#!/bin/bash

iterations=20
replicate=5
seed=123


#for n_sample in $(seq 200000 2200000 17800000); do
#for n_sample in $(seq 15600000 2200000 20000000); do
for n_sample in $(seq 15600000 2200000 17800000); do

    echo "parallel"
    for i in $(seq 1 $replicate); do
        Rscript parallel_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --workers 50 --seed $seed
    done
    sleep 5

    echo "future.apply"
    for i in $(seq 1 $replicate); do
        Rscript future_apply_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --plan multicore --workers 50 --seed $seed
    done
    sleep 5

    echo "furrr"
    for i in $(seq 1 $replicate); do
        Rscript furrr_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --plan multicore --workers 50 --seed $seed
    done
    sleep 5
    
    echo "future"
    for i in $(seq 1 $replicate); do
        Rscript future_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --plan multicore --workers 50 --seed $seed
    done
    sleep 5

    echo "future & bigmemory"
    Rscript future_bigmemory_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates $replicate --arity 50 --plan multicore --workers 50 --seed $seed
    sleep 5

    # mirai
    #Rscript mirai_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations 2 --arity 50 --plan multicore --workers 50
    
    cd ..
    echo "Sequential"
    compss_clean_procs
    sleep 1
    runcompss --lang=r --cpu_affinity=disabled kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --plot FALSE --seed $seed
    echo "RCOMPSs"
    compss_clean_procs
    sleep 2
    runcompss --lang=r --cpu_affinity=disabled kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates $replicate --arity 50 --plot FALSE --RCOMPSs --seed $seed
    compss_clean_procs
    sleep 5
    cd Comparisons
done
