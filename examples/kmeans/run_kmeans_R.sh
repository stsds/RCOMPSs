#!/usr/bin/env bash

seed=3
numpoints=10000
dimensions=2
num_centres=5
fragments=10
mode="normal"
iterations=50
epsilon=1e-9
arity=2

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
stdout_file="R-kmeans-$timestamp.out"
stderr_file="R-kmeans-$timestamp.err"
touch $stdout_file
touch $stderr_file

Rscript kmeans.R \
  --seed $seed \
  --numpoints $numpoints \
  --dimensions $dimensions \
  --num_centres $num_centres \
  --fragments $fragments \
  --mode $mode \
  --iterations $iterations \
  --epsilon $epsilon \
  --arity $arity \
  --plot TRUE \
  >>$stdout_file 2>>$stderr_file
