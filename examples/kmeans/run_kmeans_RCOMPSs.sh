#!/usr/bin/env bash

seed=1
numpoints=$(seq 1e8 5e7 5e8)
dimensions=10
num_centres=$dimensions
fragments=(10 20 30 40 50 100 200)
mode="normal"
iterations=200
epsilon=1e-9
arity=10

cd /home/zhanx0q/RCOMPSs/RCOMPSs/RCOMPSs/examples/kmeans
. ../../../config.sh

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
stdout_file="RCOMPSs-$timestamp.out"
stderr_file="RCOMPSs-$timestamp.err"
touch $stdout_file
touch $stderr_file

for point in $numpoints; do

  for frag in "${fragments[@]}"; do

    compss_clean_procs

    runcompss \
      --lang=r \
      kmeans.R \
        --seed $seed \
        --numpoints $point \
        --dimensions $dimensions \
        --num_centres $num_centres \
        --fragments $frag \
        --mode $mode \
        --iterations $iterations \
        --epsilon $epsilon \
        --arity $arity \
        --plot FALSE \
        --RCOMPSs \
        --Minimize \
        >> $stdout_file 2>> $stderr_file

  done

done
