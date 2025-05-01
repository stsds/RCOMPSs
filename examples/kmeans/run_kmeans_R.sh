#!/usr/bin/env bash

seed=1
numpoints=10000
dimensions=10
num_centres=10
fragments=10
mode="normal"
iterations=5
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
  --plot FALSE \
  --Minimize \
  >>$stdout_file 2>>$stderr_file
