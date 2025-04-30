#!/usr/bin/env bash

source $COMPSS_HOME/compssenv

export R_LIBS_USER=$COMPSS_HOME/Bindings/RCOMPSs/user_libs:$R_LIBS_USER
export LD_LIBRARY_PATH=$COMPSS_HOME/Bindings/bindings-common/lib:$LD_LIBRARY_PATH

# Define script variables
scriptDir=$(pwd)/$(dirname $0)
execFile=${scriptDir}/kmeans.R

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
  --log_dir=/scratch/$USER/bandwidth \
  --master_working_dir=/scratch/$USER/bandwidth/master_dir \
  --worker_working_dir=/scratch/$USER/bandwidth/worker_dir \
  --cpu_affinity="disabled" \
  $execFile $@

######################################################
# APPLICATION EXECUTION EXAMPLE
# Call:
#       ./launch_kmeans_RCOMPSs_Shaheen.sh <jobDependency> <numNodes> <executionTime> <tracing> <workerInMasterCPUs> <workerCPUs> <*kmeans_arguments>
#
# Example:
#       ./launch_kmeans_RCOMPSs_Shaheen.sh None 4 120 false 100 112 --plot FALSE --RCOMPSs --fragments 512 --arity 64 --numpoints 152730112 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
#
######################################################
