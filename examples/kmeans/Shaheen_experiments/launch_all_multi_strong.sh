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
./launch_kmeans_RCOMPSs_Shaheen.sh $jobID 1 120 false 128 128 --plot FALSE --RCOMPSs --fragments 4096 --arity 64 --numpoints 1221840896 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_Shaheen.sh $jobID 2 120 false 128 128 --plot FALSE --RCOMPSs --fragments 4096 --arity 64 --numpoints 1221840896 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_Shaheen.sh $jobID 4 120 false 128 128 --plot FALSE --RCOMPSs --fragments 4096 --arity 64 --numpoints 1221840896 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_Shaheen.sh $jobID 8 120 false 128 128 --plot FALSE --RCOMPSs --fragments 4096 --arity 64 --numpoints 1221840896 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_Shaheen.sh $jobID 16 120 false 128 128 --plot FALSE --RCOMPSs --fragments 4096 --arity 64 --numpoints 1221840896 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_Shaheen.sh $jobID 32 120 false 128 128 --plot FALSE --RCOMPSs --fragments 4096 --arity 64 --numpoints 1221840896 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
cd Shaheen_experiments
