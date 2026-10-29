#!/usr/bin/env bash
set -euo pipefail
export CAMPAIGN_ROOT=$HOME/software/rcompss-20261029/ibex-campaign
cd "$CAMPAIGN_ROOT"
source env.sh
module load intel/2022.3 mkl/latest
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
export PARSEC_GEMM=$HOME/exageostat_parsec_2025/exageostat-dev-gb24-gpu/build/hicma-x/dplasma/tests/testing_dgemm
export PKG_CPPFLAGS="-I$CUDA_HOME/include"
export PKG_LIBS="-L$CUDA_HOME/lib64 -Wl,-rpath,$CUDA_HOME/lib64 -lcudart"
export CAMPAIGN_GPUS=$CUDA_VISIBLE_DEVICES
export CAMPAIGN_REQUIRE_NVML=1
python3 -c 'import pynvml as nv;nv.nvmlInit();assert nv.nvmlDeviceGetCount()==4;nv.nvmlShutdown()'
test "${SLURM_JOB_NUM_NODES:-0}" = 1
ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10 "$(hostname)" true
sha256sum inputs.cpp tasks.R benchmark.R campaign.py measure.py \
  "$R_LIBS_USER/RCOMPSs/libs/RCOMPSs.so" "$PARSEC_GEMM" \
  "$COMPSS_HOME/Runtime/scripts/system/adaptors/nio/pipers/rcompss_executor" > logs/artifact-sha256.txt
java -version > logs/java-version.txt 2>&1
Rscript --vanilla -e 'print(sessionInfo());print(extSoftVersion())' > logs/R-session.txt
nvidia-smi topo -m > logs/gpu-topology.txt
ldd "$PARSEC_GEMM" > logs/parsec-node-ldd.log
if grep -q 'not found' logs/parsec-node-ldd.log; then exit 3; fi
Rscript --vanilla -e 'library(RCOMPSs);Rcpp::sourceCpp("inputs.cpp",cacheDir="cpp-cache",rebuild=FALSE)'
CUDA_VISIBLE_DEVICES='' Rscript --vanilla -e 'library(RCOMPSs);testthat::test_dir("/home/abdullsm/software/RCOMPSs/tests/testthat",stop_on_failure=TRUE)' > logs/node-cpu-tests.log 2>&1
RCOMPSs_TEST_GPU=true Rscript --vanilla -e 'library(RCOMPSs);testthat::test_dir("/home/abdullsm/software/RCOMPSs/tests/testthat",stop_on_failure=TRUE)' > logs/node-gpu-tests.log 2>&1
# Four-GPU numerical preflight. Production-size PaRSEC output is not checked
# by a complete CPU GEMM; RCOMPSs validates sampled entries in every block.
LD_PRELOAD=/usr/lib64/libopenblas-r0.3.21.so "$PARSEC_GEMM" -N 4096 -t 1024 -T 1024 -c 4 -g 4 -x -- --mca bind_threads 0 > logs/parsec-node-gpu-check.log 2>&1
if grep -q 'FAILED' logs/parsec-node-gpu-check.log; then exit 4; fi
grep -q 'PASSED' logs/parsec-node-gpu-check.log
python3 campaign.py
python3 summarize.py "$CAMPAIGN_ROOT"
Rscript --vanilla plot.R "$CAMPAIGN_ROOT"
date -u > FIGURES_READY
