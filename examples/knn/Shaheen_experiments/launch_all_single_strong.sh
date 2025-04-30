#!/usr/bin/env bash

wait_and_get_jobID() {
  # Wait
  sleep 6

  # Get jobID
  jobID=$(squeue -h | sort -k1 | tail -n 1 | cut -c11-18)
  echo "jobID = ${jobID}"
}

jobID="None"

./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 600 false 1 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize 
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 600 false 2 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 120 false 4 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 120 false 8 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 120 false 16 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 120 false 32 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 120 false 48 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 120 false 64 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 120 false 80 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 120 false 96 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 120 false 112 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 120 false 128 128 --seed 2 --n_train 1228800 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 96 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
