#!/usr/bin/env bash

if [ -f $COMPSS_HOME/compssenv ]; then
  source $COMPSS_HOME/compssenv
fi

export R_LIBS_USER=$COMPSS_HOME/Bindings/RCOMPSs/user_libs:$R_LIBS_USER
export LD_LIBRARY_PATH=$COMPSS_HOME/Bindings/bindings-common/lib:$LD_LIBRARY_PATH

seed=2
n_train=1000
n_test=2000
dimensions=10
num_class=5
fragments_train=5
fragments_test=10
knn=5
arity=2

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
stdout_file="RCOMPSs-knn-$timestamp.out"
stderr_file="RCOMPSs-knn-$timestamp.err"
touch $stdout_file
touch $stderr_file

compss_clean_procs

runcompss \
  --lang=r \
  knn.R \
  --seed $seed \
  --n_train $n_train \
  --n_test $n_test \
  --dimensions $dimensions \
  --num_class $num_class \
  --fragments_train $fragments_train \
  --fragments_test $fragments_test \
  --knn $knn \
  --arity $arity \
  --RCOMPSs \
  --Minimize \
  >>$stdout_file 2>>$stderr_file
