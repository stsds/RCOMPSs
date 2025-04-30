#!/bin/bash -e

source $COMPSS_HOME/compssenv

export R_LIBS_USER=$COMPSS_HOME/Bindings/RCOMPSs/user_libs:$R_LIBS_USER
export LD_LIBRARY_PATH=$COMPSS_HOME/Bindings/bindings-common/lib:$LD_LIBRARY_PATH

# Define script variables
scriptDir=$(pwd)/$(dirname $0)
execFile=${scriptDir}/knn.R

# Retrieve arguments
jobDependency=$1
numNodes=$2
executionTime=$3
tracing=$4
worker_in_master_cpus=$5
cpus_per_node=$6

# Leave application args on $@
shift 6

# Enqueue the application
enqueue_compss \
  --job_dependency=$jobDependency \
  --queue=workq \
  --project_name=k10164 \
  --num_nodes=$numNodes \
  --exec_time=$executionTime \
  --log_level=off \
  --lang=r \
  --tracing=$tracing \
  --graph=$tracing \
  --worker_in_master_cpus=$worker_in_master_cpus \
  --cpus_per_node=$cpus_per_node \
  --scheduler=es.bsc.compss.scheduler.orderstrict.fifo.FifoTS \
  --log_dir=/scratch/$USER/iops \
  --master_working_dir=/scratch/$USER/iops/master_dir \
  --worker_working_dir=/scratch/$USER/iops/worker_dir \
  --cpu_affinity="disabled" \
  $execFile $@

######################################################
# APPLICATION EXECUTION EXAMPLE
# Call:
#       ./launch_knn_RCOMPSs_Shaheen.sh <jobDependency> <numNodes> <executionTime> <tracing> <workerInMasterCPUs> <workerCPUs> <*knn_arguments>
#
# Example:
#       ./launch_knn_RCOMPSs_Shaheen.sh None 4 40 false 100 112 --seed 2 --n_train 8000 --n_test 4088000 --dimensions 50 --num_class 5 --fragments_train 1 --fragments_test 511 --knn 30 --arity 103 --RCOMPSs --Minimize
#
######################################################
