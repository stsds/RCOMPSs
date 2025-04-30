#!/usr/bin/env bash

wait_and_get_jobID() {
  # Wait
  sleep 6

  # Get jobID
  jobID=$(squeue -h | sort -k1 | tail -n 1 | cut -c11-18)
  echo "jobID = ${jobID}"
}

jobID="None"


##################################
# Single node - weak scalability #
##################################

./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 1 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 864000 --iterations 2 --dimensions 50 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 2 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 1728000 --iterations 2 --dimensions 50 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 4 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 3456000 --iterations 2 --dimensions 50 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 8 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 6912000 --iterations 2 --dimensions 50 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 16 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 13824000 --iterations 2 --dimensions 50 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 32 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 27648000 --iterations 2 --dimensions 50 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 64 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 55296000 --iterations 2 --dimensions 50 --seed 2
wait_and_get_jobID
#./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 128 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 110592000 --iterations 2 --dimensions 50 --seed 2
#wait_and_get_jobID


#####################################
# Single nodes - strong scalability #
#####################################

./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 1 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 23040000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 2 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 23040000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 4 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 23040000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 8 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 23040000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 16 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 23040000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 32 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 23040000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 64 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 23040000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
#./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 100 112 --plot FALSE --RCOMPSs --fragments 128 --arity 128 --numpoints 23040000 --iterations 2 --dimensions 100 --seed 2
#wait_and_get_jobID


#####################################
# Multiple nodes - weak scalability #
#####################################

./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 9545640 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 2 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 19091280 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 4 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 38182560 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 8 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 76365120 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 16 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 152730240 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 32 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 305460480 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 64 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 610920960 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
#./launch_kmeans_RCOMPSs.sh $jobID 128 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 1221841920 --iterations 2 --dimensions 100 --seed 2
#wait_and_get_jobID


#######################################
# Multiple nodes - strong scalability #
#######################################

./launch_kmeans_RCOMPSs.sh $jobID 1 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 1223800000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 2 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 1223800000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 4 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 1223800000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 8 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 1223800000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 16 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 1223800000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 32 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 1223800000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
./launch_kmeans_RCOMPSs.sh $jobID 64 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 1223800000 --iterations 2 --dimensions 100 --seed 2
wait_and_get_jobID
#./launch_kmeans_RCOMPSs.sh $jobID 128 20 false 100 112 --plot FALSE --RCOMPSs --fragments 24476 --arity 128 --numpoints 1223800000 --iterations 2 --dimensions 100 --seed 2
#wait_and_get_jobID


