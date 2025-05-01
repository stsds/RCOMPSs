#!/usr/bin/env bash

if [ -f $COMPSS_HOME/compssenv ]; then
  source $COMPSS_HOME/compssenv
fi

export R_LIBS_USER=$COMPSS_HOME/Bindings/RCOMPSs/user_libs:$R_LIBS_USER
export LD_LIBRARY_PATH=$COMPSS_HOME/Bindings/bindings-common/lib:$LD_LIBRARY_PATH

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
stdout_file="RCOMPSs-addition-$timestamp.out"
stderr_file="RCOMPSs-addition-$timestamp.err"
touch $stdout_file
touch $stderr_file

compss_clean_procs

runcompss \
  --lang=r \
  addition.R \
    >> $stdout_file 2>> $stderr_file

