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
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 12 112 --plot FALSE --RCOMPSs --fragments 12 --arity 8 --numpoints 3104640 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 16 112 --plot FALSE --RCOMPSs --fragments 16 --arity 8 --numpoints 4139520 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 20 112 --plot FALSE --RCOMPSs --fragments 20 --arity 8 --numpoints 5174400 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 24 112 --plot FALSE --RCOMPSs --fragments 24 --arity 8 --numpoints 6209280 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 28 112 --plot FALSE --RCOMPSs --fragments 28 --arity 8 --numpoints 7244160 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 32 112 --plot FALSE --RCOMPSs --fragments 32 --arity 8 --numpoints 8279040 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 36 112 --plot FALSE --RCOMPSs --fragments 36 --arity 8 --numpoints 9313920 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 40 112 --plot FALSE --RCOMPSs --fragments 40 --arity 8 --numpoints 10348800 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 44 112 --plot FALSE --RCOMPSs --fragments 44 --arity 8 --numpoints 11383680 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 48 112 --plot FALSE --RCOMPSs --fragments 48 --arity 8 --numpoints 12418560 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 52 112 --plot FALSE --RCOMPSs --fragments 52 --arity 8 --numpoints 13453440 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 56 112 --plot FALSE --RCOMPSs --fragments 56 --arity 8 --numpoints 14488320 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 60 112 --plot FALSE --RCOMPSs --fragments 60 --arity 8 --numpoints 15523200 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 64 112 --plot FALSE --RCOMPSs --fragments 64 --arity 8 --numpoints 16558080 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 68 112 --plot FALSE --RCOMPSs --fragments 68 --arity 8 --numpoints 17592960 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 72 112 --plot FALSE --RCOMPSs --fragments 72 --arity 8 --numpoints 18627840 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 76 112 --plot FALSE --RCOMPSs --fragments 76 --arity 8 --numpoints 11262720 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
wait_and_get_jobID
./launch_kmeans_RCOMPSs_MN5.sh $jobID 1 20 false 80 112 --plot FALSE --RCOMPSs --fragments 80 --arity 8 --numpoints 20697600 --iterations 2 --dimensions 200 --seed 2 --mode normal --Minimize
cd MN5_experiments