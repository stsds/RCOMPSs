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
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 1 112 --plot FALSE --RCOMPSs --fragments 1 --arity 8 --numpoints 258720 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 2 112 --plot FALSE --RCOMPSs --fragments 2 --arity 8 --numpoints 517440 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 4 112 --plot FALSE --RCOMPSs --fragments 4 --arity 8 --numpoints 1034880 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 8 112 --plot FALSE --RCOMPSs --fragments 8 --arity 8 --numpoints 2069760 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 16 112 --plot FALSE --RCOMPSs --fragments 16 --arity 8 --numpoints 4139520 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 32 112 --plot FALSE --RCOMPSs --fragments 32 --arity 8 --numpoints 8279040 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 48 112 --plot FALSE --RCOMPSs --fragments 48 --arity 8 --numpoints 12418560 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 64 112 --plot FALSE --RCOMPSs --fragments 64 --arity 8 --numpoints 16558080 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 80 112 --plot FALSE --RCOMPSs --fragments 80 --arity 8 --numpoints 20697600 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
cd MN5_experiments
