#!/usr/bin/env bash

wait_and_get_jobID() {
  # Wait
  sleep 6

  # Get jobID
  jobID=$(squeue -h | sort -k1 | tail -n 1 | cut -c11-18)
  echo "jobID = ${jobID}"
}

jobID="None"

./launch_kmeans_RCOMPSs.sh $jobID 1 120 false 100 112 --plot FALSE --RCOMPSs --fragments 128 --arity 64 --numpoints 38182528 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 2 120 false 100 112 --plot FALSE --RCOMPSs --fragments 256 --arity 64 --numpoints 76365056 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 4 120 false 100 112 --plot FALSE --RCOMPSs --fragments 512 --arity 64 --numpoints 152730112 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 8 120 false 100 112 --plot FALSE --RCOMPSs --fragments 1024 --arity 64 --numpoints 305460224 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 16 120 false 100 112 --plot FALSE --RCOMPSs --fragments 2048 --arity 64 --numpoints 610920448 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 32 120 false 100 112 --plot FALSE --RCOMPSs --fragments 4096 --arity 64 --numpoints 1221840896 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize

