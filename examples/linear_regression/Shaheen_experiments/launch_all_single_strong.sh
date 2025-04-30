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
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 1440 false 1 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 1440 false 2 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 1440 false 4 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 720 false 8 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 360 false 16 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 180 false 32 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 180 false 48 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 180 false 64 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 180 false 80 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 50 false 96 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 40 false 112 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 40 false 128 128 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 1024 --fragments_pred 256 --arity 2 --RCOMPSs --Minimize
cd Shaheen_experiments
