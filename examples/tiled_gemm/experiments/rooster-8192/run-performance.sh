#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/software/rcompss-20261029/gemm-8192-tile-sweep"
source "$HOME/software/rcompss-20261029/tiled-gemm-20261029/parsec-env.sh"
for tile in 512 1024 2048; do
 timeout 120 taskset -c 0 "$PARSEC_GEMM" -N 8192 -t "$tile" -T "$tile" -c 1 -g 1 --nruns 4 -v=3 -- --mca device_show_statistics 1 > "logs/parsec-performance-$tile.log" 2>&1
done
