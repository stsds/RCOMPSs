#!/usr/bin/env bash

if [ -f $COMPSS_HOME/compssenv ]; then
  source $COMPSS_HOME/compssenv
fi

export R_LIBS_USER=$COMPSS_HOME/Bindings/RCOMPSs/user_libs:$R_LIBS_USER
export LD_LIBRARY_PATH=$COMPSS_HOME/Bindings/bindings-common/lib:$LD_LIBRARY_PATH

seed=3
num_fit=1000
num_pred=100
dimensions_x=10
dimensions_y=2
fragments_fit=10
fragments_pred=10
arity=2

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
stdout_file="RCOMPSs-linear_regression-$timestamp.out"
stderr_file="RCOMPSs-linear_regression-$timestamp.err"
touch $stdout_file
touch $stderr_file

compss_clean_procs

runcompss \
  --lang=r \
  linear_regression.R \
  --seed $seed \
  --num_fit $num_fit \
  --num_pred $num_pred \
  --dimensions_x $dimensions_x \
  --dimensions_y $dimensions_y \
  --fragments_fit $fragments_fit \
  --fragments_pred $fragments_pred \
  --arity $arity \
  --RCOMPSs \
  --Minimize \
  >>$stdout_file 2>>$stderr_file
