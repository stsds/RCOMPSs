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
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 1 128 --seed 2 --num_fit 768000 --num_pred 12800 --dimensions_x 100 --dimensions_y 2 --fragments_fit 4 --fragments_pred 4 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 2 128 --seed 2 --num_fit 1536000 --num_pred 25600 --dimensions_x 100 --dimensions_y 2 --fragments_fit 8 --fragments_pred 8 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 4 128 --seed 2 --num_fit 3072000 --num_pred 51200 --dimensions_x 100 --dimensions_y 2 --fragments_fit 16 --fragments_pred 16 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 8 128 --seed 2 --num_fit 6144000 --num_pred 102400 --dimensions_x 100 --dimensions_y 2 --fragments_fit 32 --fragments_pred 32 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 16 128 --seed 2 --num_fit 12288000 --num_pred 204800 --dimensions_x 100 --dimensions_y 2 --fragments_fit 64 --fragments_pred 64 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 32 128 --seed 2 --num_fit 24576000 --num_pred 409600 --dimensions_x 100 --dimensions_y 2 --fragments_fit 128 --fragments_pred 128 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 48 128 --seed 2 --num_fit 36864000 --num_pred 614400 --dimensions_x 100 --dimensions_y 2 --fragments_fit 192 --fragments_pred 192 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 64 128 --seed 2 --num_fit 49152000 --num_pred 819200 --dimensions_x 100 --dimensions_y 2 --fragments_fit 256 --fragments_pred 256 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 80 128 --seed 2 --num_fit 61440000 --num_pred 1024000 --dimensions_x 100 --dimensions_y 2 --fragments_fit 320 --fragments_pred 320 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 96 128 --seed 2 --num_fit 73728000 --num_pred 1228800 --dimensions_x 100 --dimensions_y 2 --fragments_fit 384 --fragments_pred 384 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 112 128 --seed 2 --num_fit 86016000 --num_pred 1433600 --dimensions_x 100 --dimensions_y 2 --fragments_fit 448 --fragments_pred 448 --arity 16 --RCOMPSs --Minimize
wait_and_get_jobID
./launch_linear_regression_RCOMPSs_Shaheen.sh $jobID 1 10 false 128 128 --seed 2 --num_fit 98304000 --num_pred 1638400 --dimensions_x 100 --dimensions_y 2 --fragments_fit 512 --fragments_pred 512 --arity 16 --RCOMPSs --Minimize
cd Shaheen_experiments
