#!/bin/bash

iterations=30
replicate=1
seed=123

# Specify which algorithms to execute
#algorithms=("future_apply_bigmemory" "future_bigmemory" "RCOMPSs") # Example: ("furrr" "parallel" "future.apply")
#algorithms=("parallel" "parallel_bigmemory") # Example: ("furrr" "parallel" "future.apply")
algorithms=("parallel" "parallel_bigmemory" "future.apply" "future_apply_bigmemory" "future" "future_bigmemory" "RCOMPSs" "RCOMPSs_bigmemory")
algorithms=("parallel")
algorithms=("RCOMPSs")
algorithms=("RCOMPSs_bigmemory")

cd /home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/examples/kmeans/Comparisons

#for n_sample in $(seq 200000 2200000 17800000); do
#for n_sample in $(seq 15600000 2200000 20000000); do

#for n_sample in $(seq 15600000 2200000 17800000); do
#for n_sample in $(seq 200000 4400000 88200000); do
#for n_sample in $(seq 200000 8800000 88200000); do
#for n_sample in $(seq 200000 8800000 9000000); do
for n_sample in $(seq 200000 17600000 88200000); do

    # Only run algorithms specified in the array
    for alg in "${algorithms[@]}"; do

        if [ "$alg" == "parallel" ]; then
            echo "parallel"
            for i in $(seq 1 $replicate); do
                Rscript parallel_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --workers 50 --seed $seed
            done
        elif [ "$alg" == "parallel_bigmemory" ]; then
            echo "parallel & bigmemory"
            for i in $(seq 1 $replicate); do
                Rscript parallel_bigmemory_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --workers 50 --seed $seed
            done
        elif [ "$alg" == "future.apply" ]; then
            echo "future.apply"
            for i in $(seq 1 $replicate); do
                Rscript future_apply_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --plan multicore --workers 50 --seed $seed
            done
        elif [ "$alg" == "future_apply_bigmemory" ]; then
            echo "future.apply & bigmemory"
            for i in $(seq 1 $replicate); do
                Rscript future_apply_bigmemory_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --plan multicore --workers 50 --seed $seed
            done
        elif [ "$alg" == "furrr" ]; then
            echo "furrr"
            for i in $(seq 1 $replicate); do
                Rscript furrr_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --plan multicore --workers 50 --seed $seed
            done
        elif [ "$alg" == "future" ]; then
            echo "future"
            for i in $(seq 1 $replicate); do
                Rscript future_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --plan multicore --workers 50 --seed $seed
            done
        elif [ "$alg" == "future_bigmemory" ]; then
            echo "future & bigmemory"
            Rscript future_bigmemory_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates $replicate --arity 50 --plan multicore --workers 50 --seed $seed
        elif [ "$alg" == "RCOMPSs_bigmemory" ]; then
            echo "RCOMPSs & bigmemory"
            compss_clean_procs
            sleep 2
            runcompss --lang=r --cpu_affinity=disabled --project=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/project.xml --resources=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/resources.xml RCOMPSs_bigmemory_kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates $replicate --arity 50 --plot FALSE --RCOMPSs --seed $seed
            compss_clean_procs
        elif [ "$alg" == "Sequential" ]; then
            cd ..
            echo "Sequential"
            compss_clean_procs
            sleep 1
            runcompss --lang=r --cpu_affinity=disabled --project=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/project.xml --resources=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/resources.xml kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates 1 --arity 50 --plot FALSE --seed $seed
        elif [ "$alg" == "RCOMPSs" ]; then
            cd ..
            echo "RCOMPSs"
            compss_clean_procs
            sleep 2
            runcompss --lang=r --cpu_affinity=disabled --project=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/project.xml --resources=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/resources.xml kmeans.R -M --numpoints $n_sample --dimensions 100 --num_centres 10 --fragments 50 --mode normal --iterations $iterations --replicates $replicate --arity 50 --plot FALSE --RCOMPSs --seed $seed
        fi

        if [ "$alg" == "Sequential" ] || [ "$alg" == "RCOMPSs" ]; then
            compss_clean_procs
            rm -rf /tmp/COMPSsWorker/*
            rm -rf /home/zhanx0q/.COMPSs/*
            cd Comparisons
        fi

        sleep 5

    done
    
    compss_clean_procs
    sleep 120

done
