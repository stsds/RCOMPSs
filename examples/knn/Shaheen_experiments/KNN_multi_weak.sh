#!/bin/bash

wait_and_get_jobID() {
  #Wait
  sleep 300

 # Get jobID
 jobID=$(squeue -h | sort -k1 | tail -n 1 | cut -c1-7)
 echo "jobID = ${jobID}"
}

jobID="None"


##################################
# Single node - weak scalability #
##################################


./launch_knn_RCOMPSs_Shaheen.sh None 32 50 false 128 128 --seed 2 --n_train 8000 --n_test 32760000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 4095 --knn 30 --arity 105 --RCOMPSs --Minimize	
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh None 16 50 false 128 128 --seed 2 --n_train 8000 --n_test 16376000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 2047 --knn 30 --arity 103 --RCOMPSs --Minimize	
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh None 8 50 false 128 128 --seed 2 --n_train 8000 --n_test 8184000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 1023 --knn 30 --arity 103 --RCOMPSs --Minimize	
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh None 4 50 false 128 128 --seed 2 --n_train 8000 --n_test 4088000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 511 --knn 30 --arity 103 --RCOMPSs --Minimize	
wait_and_get_jobID
./launch_knn_RCOMPSs_Shaheen.sh None 2 50 false 128 128 --seed 2 --n_train 8000 --n_test 2040000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 255 --knn 30 --arity 129 --RCOMPSs --Minimize
wait_and_get_jobID

echo "Weak scalability of KNN (Multi-node) finished!" | mail -s "Weak scalability of KNN (Multi-node) finished!" xiran.zhang@kaust.edu.sa
