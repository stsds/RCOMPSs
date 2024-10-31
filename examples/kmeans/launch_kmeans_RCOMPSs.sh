#!/bin/bash -e

export COMPSS_PYTHON_VERSION=3.12.1
module use /apps/GPP/modulefiles/applications/COMPSs/.custom
module load TrunkJCB

export R_LIBS_USER=/gpfs/apps/MN5/GPP/COMPSs/TrunkJCB/Bindings/RCOMPSs/user_libs:$R_LIBS_USER
export LD_LIBRARY_PATH=/gpfs/apps/MN5/GPP/COMPSs/TrunkJCB/Bindings/bindings-common/lib:$LD_LIBRARY_PATH

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
    --project_name=bsc19 \
    --qos=gp_debug \
    --num_nodes=$numNodes \
    --exec_time=$executionTime \
    --worker_working_dir=$(pwd) \
    --log_level=off \
    --lang=r \
    --tracing=$tracing \
    --graph=$tracing \
    $execFile $@


#runcompss --lang=r -g kmeans.R --plot FALSE --RCOMPSs --fragments 8 --arity 2 --numpoints 9000 --iterations 4


######################################################
# APPLICATION EXECUTION EXAMPLE
# Call:
#       ./launch_kmeans_RCOMPSs.sh jobDependency numNodes executionTime tracing kmeans_args
#
# Example:
#       ./launch_kmeans_RCOMPSs.sh None 2 5 false --plot FALSE --RCOMPSs --fragments 8 --arity 2 --numpoints 9000 --iterations 4
#        ./launch_kmeans_RCOMPSs.sh None 2 20 true --plot FALSE --RCOMPSs --fragments 424 --arity 100 --numpoints 4240000 --iterations 4
#
######################################################
