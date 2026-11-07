#!/usr/bin/env bash
set -euo pipefail
scriptdir=$(cd "$(dirname "$0")" && pwd)
benchdir=${BENCHDIR:-$HOME/software/rcompss-20261029/tiled-gemm-20261029}
mkdir -p "$benchdir/logs" "$benchdir/results"
cd "$benchdir"
source "$scriptdir/parsec-env.sh"
for mode in CPU GPU; do
 if [[ $mode == CPU ]]; then cores=4; gpus=0; cpuset=0-3; else cores=1; gpus=1; cpuset=0; fi
 timeout 120 taskset -c "$cpuset" "$PARSEC_GEMM" -N 4096 -t 1024 -T 1024 -c "$cores" -g "$gpus" -x -- --mca device_show_statistics 1 > "logs/parsec-check-$mode.log" 2>&1
 for n in 2048 4096; do
  for tile in 512 1024; do
   timeout 120 taskset -c "$cpuset" "$PARSEC_GEMM" -N "$n" -t "$tile" -T "$tile" -c "$cores" -g "$gpus" --nruns 4 -v=3 -- --mca device_show_statistics 1 > "logs/parsec-$mode-$n-$tile.log" 2>&1
  done
 done
done
