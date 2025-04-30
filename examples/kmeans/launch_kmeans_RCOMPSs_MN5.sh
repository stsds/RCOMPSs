#!/usr/bin/env bash

export COMPSS_PYTHON_VERSION=3.12.1
module load COMPSs/Trunk

export R_LIBS_USER=/gpfs/apps/MN5/GPP/COMPSs/Trunk/Bindings/RCOMPSs/user_libs:$R_LIBS_USER
export LD_LIBRARY_PATH=/gpfs/apps/MN5/GPP/COMPSs/Trunk/Bindings/bindings-common/lib:$LD_LIBRARY_PATH

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
    --project_name=bsc19 \
    --qos=gp_bsccs \
    --num_nodes=$numNodes \
    --exec_time=$executionTime \
    --worker_working_dir=$(pwd) \
    --log_level=off \
    --lang=r \
    --tracing=$tracing \
    --graph=$tracing \
    --worker_in_master_cpus=$worker_in_master_cpus \
    --cpus_per_node=$cpus_per_node \
    --scheduler=es.bsc.compss.scheduler.orderstrict.fifo.FifoTS \
    --master_working_dir=$(pwd) \
    --worker_working_dir=$(pwd) \
    --cpu_affinity="disabled" \
    $execFile $@


######################################################
# APPLICATION EXECUTION EXAMPLE
# Call:
#       ./launch_kmeans_RCOMPSs_MN5.sh <jobDependency> <numNodes> <executionTime> <tracing> <workerInMasterCPUs> <workerCPUs> <*kmeans_arguments>
#
# Example:
#       ./launch_kmeans_RCOMPSs_MN5.sh None 4 120 false 100 112 --plot FALSE --RCOMPSs --fragments 512 --arity 64 --numpoints 152730112 --iterations 2 --dimensions 100 --num_centres 10 --seed 2 --mode normal --Minimize
#
######################################################
