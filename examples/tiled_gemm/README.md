# Tiled GEMM with RCOMPSs

This example computes `C = alpha * A %*% B + beta * C` in double precision.
Each task reduces all k tile pairs for an output region. `row_group` and
`column_group` batch adjacent output tiles; their defaults are 1. The master
submits all region tasks before collecting results. Rectangular matrices and
partial edge tiles are supported. Inputs must be nonempty double matrices;
transpose operations are not implemented here.

The benchmark keeps at least four CPU tasks where possible. On one GPU it
batches all output tiles into one RCOMPSs task, while the native GPU helper
still submits individual square tile GEMMs. This deliberately changes runtime
task granularity; it is not the original per-update task DAG.

- `tasks.R`: CPU `%*%` and GPU cuBLAS product tasks.
- `tiled_gemm.R`: task registration, partitioning, dependency chains and assembly.
- `benchmark.R`: correctness checks and repeated timing runs.
- `run_rooster.sh`: reproduce the Rooster RCOMPSs runs using the tested installation.
- `run-parsec.sh`, `parsec-env.sh`: run the existing PaRSEC/DPLASMA baseline.
- `summarize.py`: retain raw trials and compare medians after excluding trial 0.

The native `rcompss_gemm_tile_reduce` helper updates C directly with CPU BLAS,
avoiding intermediate R product/addition matrices. In GPU mode it keeps C in
device memory across k updates, uses nonzero beta directly in cuBLAS, and
allocates/reuses two input buffers for the whole reduction. C is downloaded
once per task. GPU output kernels are blocked by the largest input k-tile
width, including partial edges. The worker caches its GPU context; data is not shared
between output-tile tasks. The helper synchronizes before returning even when
the context is asynchronous. The older `rcompss_gpu_dgemm` API is unchanged.

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
lazy GPU initialization fixes, plus the native tile-reduction helper. No production installation is replaced.

For this localhost configuration, the launcher declares `$HOME` shared between
master and worker and places worker files under the benchmark directory. This
avoids redundant transfers of files already visible on the same filesystem.
Set `RCOMPSS_SHARED_DATA=0` to reproduce the unshared transport configuration.
This declaration is specific to the configured localhost worker. See the
[COMPSs shared-disk documentation](https://compss-doc.readthedocs.io/en/3.4/Sections/01_Installation_Configuration/03_Configuration/01_General.html).

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
data residency or task granularity. The existing DPLASMA binary uses CUDA 11.6;
the RCOMPSs package uses CUDA 12.6.3. A reserved-node, matched-build study and
larger problem sizes are needed before drawing publication-wide conclusions.

## Native regression tests

`tests/testthat/test-gemm-tile-reduce.R` exercises ragged panels, scalars, beta=0
with NaN initial C, input preservation and errors. CPU tests run without GPUs.
Set `RCOMPSs_TEST_GPU=true` to test both sync and async GPU contexts on a GPU host.

`profile_native.R` measures the native helper outside COMPSs and separately
measures serialization of its input payload. Set `PROFILE_OUTPUT` to a CSV
path before running it on a GPU host. Native-helper time excludes runtime
startup, partitioning, task serialization/transfers and final R assembly; it
must not be compared directly to end-to-end task time as a runtime speedup.
