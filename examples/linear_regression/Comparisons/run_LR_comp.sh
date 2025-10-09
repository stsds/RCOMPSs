#!/bin/bash

replicate=1
replicate_RCOMPSs=2
seed=123
dim=100
clean_compss=true
ncores=50
fragments_fit=50
fragments_pred=50

# Specify which algorithms to execute
algorithms=("parallel" "furrr" "future" "RCOMPSs")
#algorithms=("parallel" "RCOMPSs")
#algorithms=("parallel" "Sequential")
#algorithms=("RCOMPSs")
#algorithms=("furrr")

n_sample_range=(1000 5000 10000 50000 100000 500000 1000000 $(seq 5000000 5000000 40000000))

cd /home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/examples/linear_regression/Comparisons

compss_clean_procs

for n_sample in "${n_sample_range[@]}"; do

    # Only run algorithms specified in the array
    for alg in "${algorithms[@]}"; do

        if [ "$alg" == "parallel" ]; then
            echo "parallel"
            for i in $(seq 1 $replicate); do
                Rscript parallel_LR.R -M --num_fit $n_sample --num_pred $n_sample --dimensions_x $dim --dimensions_y $dim --fragments_fit $fragments_fit --fragments_pred $fragments_pred --arity 50 --ncores $ncores --seed $seed --replicates 1
            done
        elif [ "$alg" == "furrr" ]; then
            echo "furrr"
            for i in $(seq 1 $replicate); do
                Rscript furrr_LR.R -M --num_fit $n_sample --num_pred $n_sample --dimensions_x $dim --dimensions_y $dim --fragments_fit $fragments_fit --fragments_pred $fragments_pred --arity 50 --ncores $ncores --seed $seed --replicates 1
            done
        elif [ "$alg" == "future" ]; then
            echo "future"
            for i in $(seq 1 $replicate); do
                Rscript future_LR.R -M --num_fit $n_sample --num_pred $n_sample --dimensions_x $dim --dimensions_y $dim --fragments_fit $fragments_fit --fragments_pred $fragments_pred --arity 50 --ncores $ncores --seed $seed --replicates 1
            done
        elif [ "$alg" == "Sequential" ]; then
            #cd ..
            echo "Sequential"
            #compss_clean_procs
            #sleep 1
            #runcompss --lang=r --cpu_affinity=disabled --project=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/project.xml --resources=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/resources.xml --env_script=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/examples/linear_regression/sequential_env.sh linear_regression.R -M --num_fit $n_sample --num_pred $n_sample --dimensions_x $dim --dimensions_y $dim --fragments_fit $fragments_fit --fragments_pred $fragments_pred --arity 50 --seed $seed --replicates $replicate_RCOMPSs
            Rscript sequential_LR.R -M --num_fit $n_sample --num_pred $n_sample --dimensions_x $dim --dimensions_y $dim --fragments_fit $fragments_fit --fragments_pred $fragments_pred --arity 50 --ncores $ncores --seed $seed --replicates 1
        elif [ "$alg" == "RCOMPSs" ]; then
            cd ..
            echo "RCOMPSs"
            compss_clean_procs
            sleep 2
            #--env_script=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/examples/linear_regression/sequential_env.sh 
            runcompss --lang=r --cpu_affinity=disabled --project=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/project.xml --resources=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/resources.xml linear_regression.R -M --num_fit $n_sample --num_pred $n_sample --dimensions_x $dim --dimensions_y $dim --fragments_fit $fragments_fit --fragments_pred $fragments_pred --arity 50 --seed $seed --replicates $replicate_RCOMPSs --RCOMPSs
        fi

        if [ "$alg" == "RCOMPSs" ]; then
            cd Comparisons
        fi

        if [ "$clean_compss" == true ]; then
            compss_clean_procs
            rm -rf /tmp/COMPSsWorker/*
            rm -rf /home/zhanx0q/.COMPSs/*
        fi

        sleep 60

    done
    
    compss_clean_procs
    sleep 10

done
