#!/bin/bash

replicate=1
replicate_RCOMPSs=2
seed=123
dim=100
k=10
a=50
fragments_train=50 # $((n_train / 4000))
fragments_test=50 # $((n_test / 4000))
clean_compss=true
n_test_range=(1000 100000 $(seq 500000 500000 2000000))


# Specify which algorithms to execute
#algorithms=("parallel" "parallel_bigmemory" "future.apply" "future_apply_bigmemory" "future" "future_bigmemory" "RCOMPSs" "RCOMPSs_bigmemory")
algorithms=("parallel" "furrr" "future" "RCOMPSs" "Sequential")
algorithms=("parallel" "furrr" "future" "RCOMPSs")
#algorithms=("parallel" "RCOMPSs")
#algorithms=("parallel" "Sequential")
#algorithms=("parallel")
#algorithms=("RCOMPSs")
#algorithms=("furrr")
#algorithms=("future")
#algorithms=("Sequential")
#algorithms=("")

cd /home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/examples/knn/Comparisons

for n_test in "${n_test_range[@]}"; do
  #n_test=20000
  n_train=$((n_test / 2))
  echo "n_train: $n_train, n_test: $n_test, dim: $dim, fragments_train: $fragments_train, fragments_test: $fragments_test"

  # Only run algorithms specified in the array
  for alg in "${algorithms[@]}"; do

    if [ "$alg" == "parallel" ]; then
      echo "parallel"
      for i in $(seq 1 $replicate); do
        Rscript parallel_knn.R -M --n_train $n_train --n_test $n_test --dimensions $dim --num_class 5 --fragments_train $fragments_train --fragments_test $fragments_test --knn=$k --arity $a --ncores 50 --seed $seed --replicates 1
      done
    elif [ "$alg" == "furrr" ]; then
      echo "furrr"
      for i in $(seq 1 $replicate); do
        Rscript furrr_knn.R -M --n_train $n_train --n_test $n_test --dimensions $dim --num_class 5 --fragments_train $fragments_train --fragments_test $fragments_test --knn=$k --arity $a --ncores 50 --seed $seed --replicates 1
      done
    elif [ "$alg" == "future" ]; then
      echo "future"
      for i in $(seq 1 $replicate); do
        Rscript future_knn.R -M --n_train $n_train --n_test $n_test --dimensions $dim --num_class 5 --fragments_train $fragments_train --fragments_test $fragments_test --knn=$k --arity $a --ncores 50 --seed $seed --replicates 1
      done
    elif [ "$alg" == "Sequential" ]; then
      cd ..
      echo "Sequential"
      compss_clean_procs
      sleep 1
      runcompss --lang=r --cpu_affinity=disabled --project=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/project.xml --resources=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/resources.xml knn.R -M --n_train $n_train --n_test $n_test --dimensions $dim --num_class 5 --fragments_train $fragments_train --fragments_test $fragments_test --knn=$k --arity $a --seed $seed --replicates $replicate
    elif [ "$alg" == "RCOMPSs" ]; then
      cd ..
      echo "RCOMPSs"
      compss_clean_procs
      sleep 2
      runcompss --lang=r --cpu_affinity=disabled --project=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/project.xml --resources=/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/aux/resources.xml knn.R -M --n_train $n_train --n_test $n_test --dimensions $dim --num_class 5 --fragments_train $fragments_train --fragments_test $fragments_test --knn=$k --arity $a --seed $seed --replicates $replicate_RCOMPSs --RCOMPSs
    fi

    if [ "$alg" == "Sequential" ] || [ "$alg" == "RCOMPSs" ] && [ "$clean_compss" == true ]; then
      compss_clean_procs
      rm -rf /tmp/COMPSsWorker/*
      rm -rf /home/zhanx0q/.COMPSs/*
      cd Comparisons
    fi

    sleep 5

  done

  compss_clean_procs
  sleep 15

done
