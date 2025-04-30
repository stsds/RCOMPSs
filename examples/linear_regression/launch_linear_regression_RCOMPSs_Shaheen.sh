#!/bin/bash -e

source $COMPSS_HOME/compssenv

export R_LIBS_USER=$COMPSS_HOME/Bindings/RCOMPSs/user_libs:$R_LIBS_USER
export LD_LIBRARY_PATH=$COMPSS_HOME/Bindings/bindings-common/lib:$LD_LIBRARY_PATH

  # Define script variables
  scriptDir=$(pwd)/$(dirname $0)
  execFile=${scriptDir}/linear_regression.R

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
    --log_dir=/scratch/$USER/iops \
    --master_working_dir=/scratch/$USER/iops/master_dir \
    --worker_working_dir=/scratch/$USER/iops/worker_dir \
    --cpu_affinity="disabled" \
    --scheduler=es.bsc.compss.scheduler.orderstrict.fifo.FifoTS \
    $execFile $@


######################################################
# APPLICATION EXECUTION EXAMPLE
# Call:
#       ./launch_linear_regression_RCOMPSs_Shaheen.sh <jobDependency> <numNodes> <executionTime> <tracing> <workerInMasterCPUs> <workerCPUs> <*linear_regression_arguments>
#
# Example:
#       ./launch_linear_regression_RCOMPSs_Shaheen.sh None 4 50 false 100 112 --seed 2 --num_fit 10240000 --num_pred 2560000 --dimensions_x 1000 --dimensions_y 1000 --fragments_fit 512 --fragments_pred 128 --arity 2 --RCOMPSs --Minimize
#
######################################################
