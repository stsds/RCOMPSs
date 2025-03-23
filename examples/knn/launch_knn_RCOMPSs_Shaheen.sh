#!/bin/bash -e

source /scratch/zhanx0q/RCOMPSs5/COMPSs_installation/compssenv

export R_LIBS_USER=/scratch/zhanx0q/RCOMPSs5/COMPSs_installation/Bindings/RCOMPSs/user_libs:$R_LIBS_USER
export LD_LIBRARY_PATH=/scratch/zhanx0q/RCOMPSs5/COMPSs_installation/Bindings/bindings-common/lib:$LD_LIBRARY_PATH

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
  shift 4

  # Enqueue the application
  enqueue_compss \
    --job_dependency=$jobDependency \
    --queue=workq \
    --project_name=k10164 \
    --num_nodes=$numNodes \
    --exec_time=$executionTime \
    --log_level=debug \
    --lang=r \
    --tracing=$tracing \
    --graph=$tracing \
    --worker_in_master_cpus=$worker_in_master_cpus \
    --cpus_per_node=$cpus_per_node \
    --scheduler=es.bsc.compss.scheduler.orderstrict.fifo.FifoTS \
    --log_dir=/scratch/zhanx0q/bandwidth \
    --master_working_dir=/scratch/zhanx0q/bandwidth/master_dir \
    --worker_working_dir=/scratch/zhanx0q/bandwidth/worker_dir \
    --keep_workingdir \
    --cpu_affinity="disabled" \
    $execFile $@

 #    --keep_workingdir \
 #    --scheduler=es.bsc.compss.scheduler.orderstrict.fifo.FifoTS \

#runcompss --lang=r -g kmeans.R --plot FALSE --RCOMPSs --fragments 8 --arity 2 --numpoints 9000 --iterations 4


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
