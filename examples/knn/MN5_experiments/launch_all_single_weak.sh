#!/usr/bin/env bash

wait_and_get_jobID() {
  # Wait
  sleep 6

  # Get jobID
  jobID=$(squeue -h | sort -k1 | tail -n 1 | cut -c11-18)
  echo "jobID = ${jobID}"
}

jobID="None"

./launch_knn_RCOMPSs.sh $jobID 1 10 false 1 112 --seed 2 --n_train 2000 --n_test 2000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 1 --knn 30 --arity 1 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 2 112 --seed 2 --n_train 2000 --n_test 4000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 2 --knn 30 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 4 112 --seed 2 --n_train 2000 --n_test 8000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 4 --knn 30 --arity 4 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 8 112 --seed 2 --n_train 2000 --n_test 16000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 8 --knn 30 --arity 8 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 16 112 --seed 2 --n_train 2000 --n_test 32000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 16 --knn 30 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 24 112 --seed 2 --n_train 2000 --n_test 48000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 24 --knn 30 --arity 24 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 32 112 --seed 2 --n_train 2000 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 40 112 --seed 2 --n_train 2000 --n_test 80000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 40 --knn 30 --arity 40 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 48 112 --seed 2 --n_train 2000 --n_test 96000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 48 --knn 30 --arity 48 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 56 112 --seed 2 --n_train 2000 --n_test 112000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 56 --knn 30 --arity 56 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 64 112 --seed 2 --n_train 2000 --n_test 128000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 64 --knn 30 --arity 64 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 72 112 --seed 2 --n_train 2000 --n_test 144000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 72 --knn 30 --arity 72 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 76 112 --seed 2 --n_train 2000 --n_test 152000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 76 --knn 30 --arity 76 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs.sh $jobID 1 10 false 80 112 --seed 2 --n_train 2000 --n_test 160000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 80 --knn 30 --arity 80 --RCOMPSs --Minimize
