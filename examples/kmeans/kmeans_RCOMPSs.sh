#!/bin/bash

seed=1
#numpoints=$(seq 5e4 15e4 2e6)
numpoints=$(seq 1e8 5e7 5e8)
dimensions=10
num_centres=$dimensions
fragments=(10 20 30 40 50 100 200)
#fragments=(10 20)
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

    runcompss --lang=r \
      --output_profile=/home/zhanx0q/RCOMPSs/RCOMPSs/RCOMPSs/examples/kmeans/output_profile \
      --project=/home/zhanx0q/RCOMPSs/RCOMPSs/RCOMPSs/aux/default_project.xml \
      --resources=/home/zhanx0q/RCOMPSs/RCOMPSs/RCOMPSs/aux/default_resources.xml \
      kmeans.R --seed $seed \
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
