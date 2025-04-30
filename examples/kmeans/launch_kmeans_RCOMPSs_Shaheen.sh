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
#       ./launch_kmeans_RCOMPSs_Shaheen.sh jobDependency numNodes executionTime tracing kmeans_args
#
# Example:
#       ./launch_kmeans_RCOMPSs_Shaheen.sh None 2  5   true --plot FALSE --RCOMPSs --fragments 8    --arity 2   --numpoints 9000      --iterations 4
#       ./launch_kmeans_RCOMPSs_Shaheen.sh None 2  120 true --plot FALSE --RCOMPSs --fragments 1344 --arity 288 --numpoints 13440000  --iterations 4 --dimensions 10 --seed 2
#       ./launch_kmeans_RCOMPSs_Shaheen.sh None 4/8/16  300 true --plot FALSE --RCOMPSs --fragments 6048 --arity 288 --numpoints 60480000  --iterations 10 --dimensions 20 --seed 2
#       ./launch_kmeans_RCOMPSs_Shaheen.sh None 4/8/16 300 true --plot FALSE --RCOMPSs --fragments 6048 --arity 288 --numpoints 937440  --iterations 10 --dimensions 20 --seed 2
#       ./launch_kmeans_RCOMPSs_Shaheen.sh None 4/8/16 30 true --plot FALSE --RCOMPSs --fragments 6048 --arity 288 --numpoints 937440  --iterations 10 --dimensions 5 --seed 2
#
######################################################
