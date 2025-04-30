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
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 300 false 1 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 51200000 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 300 false 2 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 51200000 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 300 false 4 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 51200000 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 300 false 8 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 51200000 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 300 false 16 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 51200000 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 300 false 32 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 51200000 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 300 false 48 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 51200000 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 300 false 64 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 51200000 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 300 false 80 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 51200000 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
cd MN5_experiments