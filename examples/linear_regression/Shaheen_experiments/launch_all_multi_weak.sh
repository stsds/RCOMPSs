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
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 60 false 128 128 --seed 2 --num_fit 2560000 --num_pred 640000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 128 --fragments_pred 32 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 2 60 false 128 128 --seed 2 --num_fit 5120000 --num_pred 1280000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 256 --fragments_pred 64 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 4 50 false 128 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 512 --fragments_pred 128 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 8 40 false 128 128 --seed 2 --num_fit 20480000 --num_pred 5120000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 16 30 false 128 128 --seed 2 --num_fit 40960000 --num_pred 10240000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 2048 --fragments_pred 512 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 32 20 false 128 128 --seed 2 --num_fit 81920000 --num_pred 20480000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 4096 --fragments_pred 1024 --arity 2 --RCOMPSs --Minimize
cd Shaheen_experiments
