# Single-node Ibex A100 GEMM campaign

Status: prepared; GPU tests and measurements require Slurm allocation54779692.
No Ibex GPU results are claimed by this directory before FIGURES_READY exists.
The queue estimate on2026-10-29 was November1 and may change.

## Scope

One four-A100 node,62 schedulable physical cores (two OS-reserved cores excluded).
Use1/2/4 GPUs with the identical CPU allocation; do not combine Rooster results
or nodes in these curves. A separate fixed-N8192 sweep uses1/2/4/8/16/32/62
cores, CPU-only and with one GPU. BLAS calls are single-threaded in both
systems. PaRSEC uses the same system OpenBLAS as R via LD_PRELOAD; its MKL ABI
libraries remain loaded. Small PaRSEC CPU checks passed. The common CUDA runtime
and numerical libraries are12.4 on Ibex; the existing PaRSEC binary was compiled
with an older CUDA12 toolchain, so record both rather than claim identical builds.

Primary timer: a fresh process through complete host output and runtime shutdown.
R returns and assembles all output blocks into an ordinary matrix on the master.
PaRSEC holds its full output in host tile storage. Input generators and layouts
differ, and RCOMPSs regenerates block inputs; this compares whole implementations,
not isolated scheduler overhead. Supplementary operation timers have different
boundaries and must not be substituted into the primary graph.

## Application configuration

Tasks use the existing rcompss_gemm_tile_reduce FP64 helper, alpha=.51 beta=-.42,
inner tile2048. GPU output blocks are at most4096 square; CPU-only output blocks
are at most256x2048 and hybrid CPU blocks64x1024. Independent CPU/GPU calibration
sets a static application-level output-area split. Calibration includes task-local
input generation, validation and garbage collection, rather than kernel time alone. Record requested and actual
CPU fractions. COMPSs controls resource admission, but this is not a new dynamic
scheduler. Avoid attributing application decomposition gains to runtime changes.

The stateless generator assigns each entry a deterministic value based on global
row/column/seed; inputs agree across task partitions. Every block is downloaded
and checked against8 independently accumulated sampled dot products. These are
sampled checks, not full large-output validation. Small cases compare full CPU
outputs; PaRSEC receives four-GPU numerical preflight checks. Production-size
PaRSEC outputs are not independently checked by this harness.

A benchmark-local native adapter restores the Slurm allocation mask before the
first CUDA call and explicitly selects the assigned ordinal. Creating/deleting a
named context per GPU task prevents reusing a handle owned by a different GPU.
This adapter is explicit artifact code; do not claim that changing
CUDA_VISIBLE_DEVICES automatically rebinds a persistent CUDA context. Three
rounds of concurrent tasks must demonstrate distinct PCI buses on all4 GPUs.
Every production RCOMPSs case also records CPU affinity and observed devices.
PaRSEC device statistics must show kernels on every requested GPU.

## Capacity and memory

Allocation-only probes test three full device matrices and full-C/streamed-A/B
buffers near a conservative capacity estimate with headroom. They do not execute
GEMM, establish an absolute allocator limit, or prove that host inputs fit. A
separate one-run resident GEMM at the rounded-down fitting size records sampled
correctness and any allocation failure; it is not a repeated timing comparison. The
bounded-output task workflow is a third regime and can exceed the full-resident
boundary. Size points bracket the measured three-matrix allocation point, capped
below65536 until larger master-matrix integration is separately checked.

measure.py samples every0.5s. Host memory is simultaneous summed PSS over uniquely
case-tagged master/workers (including SSH-launched workers); shared pages are not
counted once per process as summed RSS would do. An actual COMPSs CPU smoke test
confirmed worker inclusion. GPU memory sums matching process memory per device;
peak aggregate is the simultaneous sum, not the sum of independent device peaks.
Contexts, workspace and PaRSEC cache reservations are included. A lower GPU
allocation is not proof of lower live-data memory complexity or fewer transfers;
it can represent a different caching policy and performance tradeoff. Sampling
can miss short-lived peaks.

## Execution and safety gates

1. Prepare the isolated runtime/library following INSTALL_NOTES.md; build the
   sourceCpp cache and run CPU checks before creating READY.
2. Submit allocation.sh without selecting a partition or requesting --exclusive;
   Ibex policy selects queues and rejects GPU exclusive requests. Request one
   four-A100 node,62 cores, all node memory, up to4hours.
3. The queued job waits up to20minutes for READY, then runs run-campaign.sh.
4. Strict host-key checking must pass for self-SSH using the actual hostname;
   localhost is intentionally avoided because its shared known_hosts entry is
   ambiguous across cluster nodes. No SSH security checks are disabled.
5. GPU binding, correctness, allocation probes and independent calibration gate
   the campaign. Any failed process or incorrect device count stops it. Successful
   case metadata is checkpointed; a rerun skips only successful processes and
   repeats validation checks.
6. Trial0 is excluded;3 measured repetitions alternate runtime order. GPU-count
   and size order are fixed, not randomized. Report min/max as variability, not
   confidence intervals. Do not interpret small differences as significant.
7. COMPLETE means all benchmark cases exited successfully. summarize.py then
   requires3 measured repetitions per point. plot.R generates the three PDF
   figures; FIGURES_READY is written only after that succeeds. A paper update
   still requires visual review and a caption/result audit.

The scripts use this user's isolated /home/abdullsm/software/rcompss-20261029
installation. They do not modify shared system installations or stop other jobs.
No scientific outputs are fabricated when the allocation is pending or fails.
