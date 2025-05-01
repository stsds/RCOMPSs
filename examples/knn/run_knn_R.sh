#!/usr/bin/env bash

seed=2
n_train=100
n_test=100
dimensions=2
num_class=5
fragments_train=5
fragments_test=2
knn=5
arity=2

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
stdout_file="R-knn-$timestamp.out"
stderr_file="R-knn-$timestamp.err"
touch $stdout_file
touch $stderr_file

Rscript knn.R \
  --seed $seed \
  --n_train $n_train \
  --n_test $n_test \
  --dimensions $dimensions \
  --num_class $num_class \
  --fragments_train $fragments_train \
  --fragments_test $fragments_test \
  --knn $knn \
  --arity $arity \
  --confusion_matrix \
  --plot TRUE \
  >>$stdout_file 2>>$stderr_file

