# Rooster prepared-input GEMM operation study

User-requested replacement for total-process comparison, 2026-11-04.
One node,40physical cores, only physical GV100 GPUs1,2; MKL CPU-only40threads.
Sizes4096/8192/16384/24576/32768/40000; warmup0 + measured1/2/3.

Primary timer: prepared host inputs through complete host GEMM result.
RCOMPSs prepares complete A/B/C once in /dev/shm before starting its operation
clock. Tasks copy needed panels from shared read-only host mappings: packing,
scheduling, CPU/GPU work, transfers, result collection and full host assembly
are timed. Input generation, runtime startup, independent sampled/full checks,
and shutdown are excluded. Allocation of master result C is before the timer.
Validation uses independent dot products after stopping the operation clock.
This is operation time, not device-kernel-only time.

PaRSEC uses ENQ&PROG&DEST from testing_dgemm: taskpool creation/enqueue,
progress/wait and destruction, after matrix generation. Includes scheduling and
required transfers. TIME(s) progress-only is retained diagnostically, not plotted.
MKL operation_seconds encloses cblas_dgemm on already allocated/generated inputs.
Different layouts, packing and CUDA builds (RCOMPSs12.6 / PaRSEC11.6) remain
limitations. CPU runtimes use one-thread OpenBLAS tasks, MKL40threads.

Gates: R128 full check;512twoGPUthree-round binding; PaRSEC2048 -x bothGPUcounts;
MKL sampled independent checks. Rproduction samples8dotproducts/block outside
timer; PaRSEC production lacks independent numeric validation. Active GPU counts,
code hashes, full output coverage, retries and repetitions must be audited.
No combination with earlier fresh-process measurements in rooster-v100-study.
Failed smoke operation-full-check-g2 used too few output regions for both GPUs;
retain its failure evidence; production participation remains gated.

Before driver: source env.sh, set CAMPAIGN_ROOT and CUDA PKG_CPPFLAGS/PKG_LIBS,
Rscript prepare_helpers.R. Workers load a read-only precompiled helper library;
no concurrent sourceCpp cache access. Run under flock campaign.lock. Do not
launch a duplicate. COMPLETE/FIGURE_READY only after all planned successful runs.

2026-11-04: 40K one-GPU warmup hit the1200s process cap (exit124), without
task-retry evidence; peak host PSS39.6GB, not an observed allocation failure.
Preserved the entire prior dataset under evidence/operation-cap1200. Raised
process cap to3600s and rerun all sizes/gates/calibration under a fresh code
hash. No measurements from the previous cap/version enter the final figure.
