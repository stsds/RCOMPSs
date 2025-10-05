#!/bin/bash

replicate=1
replicate_RCOMPSs=2
seed=123
dim=100
k=10
#fragments_train=25
#fragments_test=50


# Specify which algorithms to execute
#algorithms=("parallel" "parallel_bigmemory" "future.apply" "future_apply_bigmemory" "future" "future_bigmemory" "RCOMPSs" "RCOMPSs_bigmemory")
algorithms=("parallel" "furrr" "future" "RCOMPSs" "Sequential")
algorithms=("parallel" "RCOMPSs")
#algorithms=("parallel" "Sequential")
#algorithms=("parallel")
#algorithms=("RCOMPSs")
#algorithms=("furrr")
#algorithms=("future")
#algorithms=("Sequential")
#algorithms=("")

cd /home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/examples/knn/Comparisons

#for n_test in $(seq 200000 2200000 17800000); do
#for n_test in $(seq 200000 8800000 44200000); do
for n_test in $(seq 8000 8000 220000); do
  #for n_test in $(seq 200000 2200000 17800000); do
    n_train=1000000 # $((n_test / 2))
    n_test=2000000
    fragments_train=100 # $((n_train / 4000))
    fragments_test=200 # $((n_test / 4000))
    echo "n_train: $n_train, n_test: $n_test, dim: $dim, fragments_train: $fragments_train, fragments_test: $fragments_test"

    # Only run algorithms specified in the array
    for alg in "${algorithms[@]}"; do

      if [ "$alg" == "parallel" ]; then
        echo "parallel"
        for i in $(seq 1 $replicate); do
          Rscript parallel_knn.R -M --n_train $n_train --n_test $n_test --dimensions $dim --num_class 5 --fragments_train $fragments_train --fragments_test $fragments_test --knn=$k --arity 50 --ncores 50 --seed $seed --replicates 1
        done
      elif [ "$alg" == "furrr" ]; then
        echo "furrr"
        for i in $(seq 1 $replicate); do
          Rscript furrr_knn.R -M --n_train $n_train --n_test $n_test --dimensions $dim --num_class 5 --fragments_train $fragments_train --fragments_test $fragments_test --knn=$k --arity 50 --ncores 50 --seed $seed --replicates 1
        done
      elif [ "$alg" == "future" ]; then
        echo "future"
        for i in $(seq 1 $replicate); do
          Rscript future_knn.R -M --n_train $n_train --n_test $n_test --dimensions $dim --num_class 5 --fragments_train $fragments_train --fragments_test $fragments_test --knn=$k --arity 50 --ncores 50 --seed $seed --replicates 1
        done
      elif [ "$alg" == "Sequential" ]; then
        cd ..
        echo "Sequential"
        compss_clean_procs
        sleep 1
        runcompss --lang=r --cpu_affinity=disabled --project=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/project.xml --resources=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/resources.xml knn.R -M --n_train $n_train --n_test $n_test --dimensions $dim --num_class 5 --fragments_train $fragments_train --fragments_test $fragments_test --knn=$k --arity 50 --seed $seed --replicates $replicate
      elif [ "$alg" == "RCOMPSs" ]; then
        cd ..
        echo "RCOMPSs"
        compss_clean_procs
        sleep 2
        runcompss --lang=r --cpu_affinity=disabled --project=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/project.xml --resources=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/resources.xml knn.R -M --n_train $n_train --n_test $n_test --dimensions $dim --num_class 5 --fragments_train $fragments_train --fragments_test $fragments_test --knn=$k --arity 50 --seed $seed --replicates $replicate_RCOMPSs --RCOMPSs
      fi

      if [ "$alg" == "Sequential" ] || [ "$alg" == "RCOMPSs" ]; then
        compss_clean_procs
        rm -rf /tmp/COMPSsWorker/*
        rm -rf /home/zhanx0q/.COMPSs/*
        cd Comparisons
      fi

      #sleep 5

    done

    compss_clean_procs
    #sleep 120

  done
