# GEMM pilot measurements

These are exploratory Rooster results, not the forthcoming matched Ibex study.
Both use physical GPU ordinal2, one GV100, FP64 alpha=.51 beta=-.42,
one CPU core, one warmup and three measured repetitions.

8192: resident pipeline, one GEMM. `rcompss.csv` is end-to-end task time;
`native.csv` is a separate direct-call timer including allocations/transfers.
PaRSEC uses its enqueue/progress/destruction timer. Tile order alternates.
All RCOMPSs outputs checked; PaRSEC full8192 checks passed for each tile.

40000: three full matrices do not fit one32GiB GPU. The streaming reduction
keeps C resident and uploads A/B panels. Inputs are generated/partitioned
inside one GPU-constrained task, outside the operation timer. This is NOT
end-to-end task timing. Validate every row in8 seeded sampled columns against
CPU BLAS; this is not a full-output check. PaRSEC performance outputs at40000
were not independently validated. Tile2048 precedes4096, without randomization.
PaRSEC timer excludes matrix generation and runtime initialization. CUDA
versions differ (RCOMPSs12.6, PaRSEC11.6); these are not matched library builds.
The initial40000 full-payload attempt was aborted during input loading; no
end-to-end40000 result is available. Do not compare40000 and8192 timer columns
as if they measured the same boundary.

Each summary reports measured-run medians/min/max; trial0 is warmup. Existing
machine-specific launch configurations remain in the evidence archives.
