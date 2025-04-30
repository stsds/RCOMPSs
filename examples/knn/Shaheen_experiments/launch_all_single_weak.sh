#!/usr/bin/env bash

wait_and_get_jobID() {
  # Wait
  sleep 6

  # Get jobID
  jobID=$(squeue -h | sort -k1 | tail -n 1 | cut -c11-18)
  echo "jobID = ${jobID}"
}

jobID="None"

./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 1 112 --seed 2 --n_train 2000 --n_test 2000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 1 --knn 30 --arity 1 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 2 112 --seed 2 --n_train 2000 --n_test 4000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 2 --knn 30 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 4 112 --seed 2 --n_train 2000 --n_test 8000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 4 --knn 30 --arity 4 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 8 112 --seed 2 --n_train 2000 --n_test 16000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 8 --knn 30 --arity 8 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 16 112 --seed 2 --n_train 2000 --n_test 32000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 16 --knn 30 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 32 112 --seed 2 --n_train 2000 --n_test 64000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 32 --knn 30 --arity 32 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 48 112 --seed 2 --n_train 2000 --n_test 96000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 48 --knn 30 --arity 48 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 64 112 --seed 2 --n_train 2000 --n_test 128000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 64 --knn 30 --arity 64 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 80 112 --seed 2 --n_train 2000 --n_test 160000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 80 --knn 30 --arity 80 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 96 112 --seed 2 --n_train 2000 --n_test 192000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 96 --knn 30 --arity 96 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 112 112 --seed 2 --n_train 2000 --n_test 224000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 112 --knn 30 --arity 112 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh $jobID 1 10 false 128 112 --seed 2 --n_train 2000 --n_test 256000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 128 --knn 30 --arity 128 --RCOMPSs --Minimize
