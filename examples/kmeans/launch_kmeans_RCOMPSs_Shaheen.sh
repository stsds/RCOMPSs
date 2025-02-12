#!/bin/bash -e

source /scratch/zhanx0q/RCOMPSs4/COMPSs_installation/compssenv

export R_LIBS_USER=/scratch/zhanx0q/RCOMPSs4/COMPSs_installation/Bindings/RCOMPSs/user_libs:$R_LIBS_USER
export LD_LIBRARY_PATH=/scratch/zhanx0q/RCOMPSs4/COMPSs_installation/Bindings/bindings-common/lib:$LD_LIBRARY_PATH

  # Define script variables
  scriptDir=$(pwd)/$(dirname $0)
  execFile=${scriptDir}/kmeans.R

  # Retrieve arguments
  jobDependency=$1
  numNodes=$2
  executionTime=$3
  tracing=$4

  # Leave application args on $@
  shift 4

  # Enqueue the application
  enqueue_compss \
    --job_dependency=$jobDependency \
    --queue=workq \
    --project_name=k10164 \
    --num_nodes=$numNodes \
    --exec_time=$executionTime \
    --worker_working_dir=$(pwd) \
    --log_level=off \
    --lang=r \
    --tracing=$tracing \
    --graph=$tracing \
    --keep_workingdir \
    $execFile $@


#runcompss --lang=r -g kmeans.R --plot FALSE --RCOMPSs --fragments 8 --arity 2 --numpoints 9000 --iterations 4


######################################################
# APPLICATION EXECUTION EXAMPLE
# Call:
#       ./launch_kmeans_RCOMPSs.sh jobDependency numNodes executionTime tracing kmeans_args
#
# Example:
#       ./launch_kmeans_RCOMPSs.sh None 2 5 true --plot FALSE --RCOMPSs --fragments 8 --arity 2 --numpoints 9000 --iterations 4
#        ./launch_kmeans_RCOMPSs.sh None 2 120 true --plot FALSE --RCOMPSs --fragments 1344 --arity 288 --numpoints 13440000 --iterations 4 --dimensions 10 --seed 2
#
######################################################
