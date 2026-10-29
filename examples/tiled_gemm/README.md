# Tiled GEMM with RCOMPSs

This example computes `C = alpha * A %*% B + beta * C` in double precision.
Each task updates one output tile using one pair of input tiles. Successive
updates to an output tile pass its future to the next task; independent output
tiles can run concurrently. The master submits the DAG before collecting results.
Rectangular matrices and partial edge tiles are supported. Inputs must be
nonempty double matrices; transpose operations are not implemented here.

- `tasks.R`: CPU `%*%` and GPU cuBLAS product tasks.
- `tiled_gemm.R`: task registration, partitioning, dependency chains and assembly.
- `benchmark.R`: correctness checks and repeated timing runs.
- `run_rooster.sh`: reproduce the Rooster RCOMPSs runs using the tested installation.
- `run-parsec.sh`, `parsec-env.sh`: run the existing PaRSEC/DPLASMA baseline.
- `summarize.py`: retain raw trials and compare medians after excluding trial 0.

The GPU binding currently only accepts `beta=0`, so the GPU task returns the
product to the host and adds `beta*C` in R. The worker caches its GPU context,
but GPU tile buffers/data are not retained between tasks. This is a correct
baseline application, not an optimized GPU-resident GEMM implementation.

## Run on Rooster

```bash
bash examples/tiled_gemm/run_rooster.sh
bash examples/tiled_gemm/run-parsec.sh
python3 examples/tiled_gemm/summarize.py "$HOME/software/rcompss-20261029/tiled-gemm-20261029"
```

The launcher uses four CPU workers in CPU mode, and one CPU worker plus one
Quadro GV100 in GPU mode. BLAS kernels use one thread per worker. Paths are
configurable through `BENCHDIR`, `RCOMPSS_LIBRARY`, and `GPU_ORDINAL`.
The tested package includes the matrix serialization, first-call context, and
lazy GPU initialization fixes. No production installation is replaced.

The driver checks scalar, rectangular, and ragged-edge cases against R BLAS.
It then benchmarks square sizes 2048 and 4096 with tile sizes 512 and 1024.
For every configuration, trial 0 is warm-up and trials 1–3 are measured. Every
result is checked against `0.51*(A%*%B)-0.42*C`; this matches the alpha/beta used
by the existing DPLASMA `testing_dgemm` executable. Matrices use reproducible
random inputs; RCOMPSs and DPLASMA use their own different random generators.

## Timing definition

RCOMPSs `seconds` starts after matrix creation and tile partitioning, includes
submission, serialization/transfers, task execution, waiting and host assembly,
and excludes runtime startup, reference computation and validation. The
`submission_seconds` interval overlaps worker execution and is not an additive
component to combine with execution time. CPU resources include runtime overhead.

The Rooster PaRSEC comparison uses DPLASMA `testing_dgemm`, not a synthetic
replacement for PaRSEC. Compare with its `ENQ&PROG&DEST` time, which includes
taskpool creation/enqueue, progress/wait and destruction. Data starts in host
tile storage and the test releases device data between repetitions. Native
PaRSEC does not serialize R objects or assemble an R matrix. Its GPU mode is a
heterogeneous 1-CPU-plus-1-GPU configuration, not a forced GPU-only run.

The comparison is a single-node application baseline. It does not isolate
runtime overhead from R bindings, filesystem transport, BLAS/cuBLAS versions,
data residency or host accumulation. The existing DPLASMA binary uses CUDA 11.6;
the RCOMPSs package uses CUDA 12.6.3. A reserved-node, matched-build study and
larger problem sizes are needed before drawing publication-wide conclusions.
