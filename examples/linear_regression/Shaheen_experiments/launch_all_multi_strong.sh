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
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 1200 false 128 128 --seed 2 --num_fit 81920000 --num_pred 20480000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 4096 --fragments_pred 1024 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 2 800 false 128 128 --seed 2 --num_fit 81920000 --num_pred 20480000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 4096 --fragments_pred 1024 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 4 400 false 128 128 --seed 2 --num_fit 81920000 --num_pred 20480000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 4096 --fragments_pred 1024 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 8 300 false 128 128 --seed 2 --num_fit 81920000 --num_pred 20480000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 4096 --fragments_pred 1024 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 16 200 false 128 128 --seed 2 --num_fit 81920000 --num_pred 20480000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 4096 --fragments_pred 1024 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 32 120 false 128 128 --seed 2 --num_fit 81920000 --num_pred 20480000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 4096 --fragments_pred 1024 --arity 2 --RCOMPSs --Minimize
cd Shaheen_experiments
