#!/usr/bin/env bash

export COMPSS_PYTHON_VERSION=3.12.1
module load COMPSs/Trunk

export R_LIBS_USER=/gpfs/apps/MN5/GPP/COMPSs/Trunk/Bindings/RCOMPSs/user_libs:$R_LIBS_USER
export LD_LIBRARY_PATH=/gpfs/apps/MN5/GPP/COMPSs/Trunk/Bindings/bindings-common/lib:$LD_LIBRARY_PATH

  # Define script variables
  scriptDir=$(pwd)/$(dirname $0)
  execFile=${scriptDir}/../linear_regression.R

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
    --qos=gp_debug \
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
#       ./launch_linear_regression_RCOMPSs.sh jobDependency numNodes executionTime tracing kmeans_args
#
# Example:
#       ./launch_linear_regression_RCOMPSs.sh None 2 5 false 0 112 --plot FALSE --RCOMPSs --fragments 8 --arity 2 --numpoints 9000 --iterations 4
#       ./launch_linear_regression_RCOMPSs.sh None 2 20 true 0 112 --plot FALSE --RCOMPSs --fragments 424 --arity 100 --numpoints 4240000 --iterations 4
#
######################################################
