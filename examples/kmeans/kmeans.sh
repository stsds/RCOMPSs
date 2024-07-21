#!/bin/bash

seed=1
#numpoints=$(seq 5e4 15e4 2e6)
numpoints=$(seq 5e3 5e3 10e3)
dimensions=10
num_centres=$dimensions
#fragments=(10 20 30 40 52 104 208)
fragments=(10 20)
mode="normal"
iterations=200
epsilon=1e-9
arity=2

cd /home/zhanx0q/RCOMPSs/RCOMPSs/RCOMPSs/examples/kmeans
. ../../../config.sh

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
      --RCOMPSs 
      #--Minimize

  done

done
