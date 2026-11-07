#!/usr/bin/env bash
#SBATCH --job-name=rcompss-a100-study
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=62
#SBATCH --gres=gpu:a100:4
#SBATCH --constraint=a100&4gpus
#SBATCH --mem=0
#SBATCH --time=04:00:00
#SBATCH --output=/home/abdullsm/software/rcompss-20261029/ibex-campaign/logs/allocation-%j.log
set -euo pipefail
root=$HOME/software/rcompss-20261029/ibex-campaign
hostname > "$root/node.txt"
lscpu > "$root/lscpu.txt"
nvidia-smi -q > "$root/gpus.txt"
printf '%s\n' "$SLURM_JOB_ID" > "$root/jobid.txt"
for attempt in $(seq 1 120); do
 if [[ -f "$root/READY" ]]; then exec bash "$root/run-campaign.sh"; fi
 sleep 10
done
echo 'Software preparation did not finish within20minutes; allocation released.'
exit 2
