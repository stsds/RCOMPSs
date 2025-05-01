#!/usr/bin/env bash

seed=3
num_fit=1000
num_pred=100
dimensions_x=10
dimensions_y=2
fragments_fit=10
fragments_pred=10
arity=2

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
stdout_file="R-linear_regression-$timestamp.out"
stderr_file="R-linear_regression-$timestamp.err"
touch $stdout_file
touch $stderr_file

Rscript linear_regression.R \
  --seed $seed \
  --num_fit $num_fit \
  --num_pred $num_pred \
  --dimensions_x $dimensions_x \
  --dimensions_y $dimensions_y \
  --fragments_fit $fragments_fit \
  --fragments_pred $fragments_pred \
  --arity $arity \
  --compare_accuracy \
  >>$stdout_file 2>>$stderr_file
