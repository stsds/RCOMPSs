# Rooster V100 GEMM size study

Requested comparison: RCOMPSs and PaRSEC with1/2 physical GV10032GiB GPUs
(physical ordinals1,2; RTX ordinal0 excluded), plus CPU-only MKL40threads.
One shared-memory Rooster host,40physical CPU cores in each configuration.
The MKL baseline is CPU-only, repeated unchanged in both GPU-count panels.

Sizes4096,8192,16384,24576,32768,40000. Trial0 excluded; trials1/2/3 measured.
Alternating runtime order. Fixed2048 tile for the runtime workflows.
RCOMPSs uses independent CPU/GPU calibration to choose a static application
output-region split; this is not a new scheduler. Full C assembled on master.

Primary timing: measurement.json wall_seconds (verify actual JSON field), fresh
process through input generation, validation where implemented, complete host
output, runtime shutdown. Do not mix operation_seconds or ENQ&PROG&DEST into
that plot. RCOMPSs regenerates input panels and uses a different input layout
from PaRSEC; compares whole implementations rather than scheduler overhead.
PaRSEC CPU calls preload the same system OpenBLAS used by R, one BLAS thread
per task; CPU MKL uses40threads. Different CUDA builds12.6/11.6 are a limitation.

Correctness gates: RCOMPSs128 full-output check, twoGPU512 binding probe three
rounds; PaRSEC2048 four-transpose checker with1/2GPUs. MKL128 independent
sampled dot-product smoke passed. Production RCOMPSs checks8dot products per
block, MKL8dot products overall. Production PaRSEC not independently validated.
GPU activity and PCI IDs retained. Empty configured GPU activity is annotated,
not silently treated as all devices participating.

run.py runs under campaign.lock via flock. Never duplicate an active campaign.
Per-process timeout1200seconds. COMPLETE only after every planned case passes.
Failed attempts retained. Code hash prevents reuse after measurement-code edits.
Do not combine with the still-pending separate Ibex A100 study.

Main log: campaign.log. Per-case stdout.log/timing.csv/measurement.json and
GPU-usage metadata under results/. Audit3successful measured runs per point,
identical code hash and correct timers before plotting and adding to GPU paper
6ae2f8887c9d7131e3f17e54. Do not edit CPU arXiv paper67ced51898597fe9654d9749.

2026-11-04 correction: v1 runs had concurrent Rcpp sourceCpp cache read/write
errors and COMPSs task retries. All v1 results, scripts, and logs are preserved
under evidence/v1-cache-race. They must not be combined with replacement runs.
prepare_helpers.R compiles inputs.cpp once before any benchmark process; workers
source the generated read-only wrapper and load the same shared library directly.
Preparation requires PKG_CPPFLAGS/PKG_LIBS from campaign.py's CUDA configuration.
A 40-process concurrent helper-load/input-generation check passed. All validation
gates, calibration, warmups, and measurements are rerun under a new code hash.
