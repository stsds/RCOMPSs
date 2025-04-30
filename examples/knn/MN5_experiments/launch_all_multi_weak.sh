#!/usr/bin/env bash

wait_and_get_jobID() {
  # Wait
  sleep 6

  # Get jobID
  jobID=$(squeue -h | sort -k1 | tail -n 1 | cut -c11-18)
  echo "jobID = ${jobID}"
}

jobID="None"

cd ..
./launch_knn_RCOMPSs_MN5.sh $jobID 1 60 false 100 112 --seed 2 --n_train 8000 --n_test 1016000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 127 --knn 30 --arity 127 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_MN5.sh $jobID 2 50 false 100 112 --seed 2 --n_train 8000 --n_test 2040000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 255 --knn 30 --arity 129 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_MN5.sh $jobID 4 40 false 100 112 --seed 2 --n_train 8000 --n_test 4088000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 511 --knn 30 --arity 103 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_MN5.sh $jobID 8 30 false 100 112 --seed 2 --n_train 8000 --n_test 8184000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 1023 --knn 30 --arity 103 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_MN5.sh $jobID 16 30 false 100 112 --seed 2 --n_train 8000 --n_test 16376000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 2047 --knn 30 --arity 103 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_knn_RCOMPSs_MN5.sh $jobID 32 30 false 100 112 --seed 2 --n_train 8000 --n_test 32760000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 4095 --knn 30 --arity 105 --RCOMPSs --Minimize
cd MN5_experiments
