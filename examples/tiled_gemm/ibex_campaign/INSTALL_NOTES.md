# Prepared Ibex installation

Isolated prefix: /home/abdullsm/software/rcompss-20261029/ibex-campaign.
COMPSs prefix: /home/abdullsm/software/rcompss-20261029/COMPSs.

The COMPSs3.3.3.post2508 development installation was copied from Rooster,
excluding its R user libraries. Its bindings-common library resolves correctly
against Java19 on Ibex. The R native worker and executor were rebuilt on Ibex;
no Ubuntu R package binary is used by the Ibex campaign.

`env.sh` loads R4.6.1/GNU12.2, Java19, CUDA12.4.1 and CMake3.28.4. The R module
also loads its Java25 dependency; JAVA_HOME/PATH for COMPSs are then set by the
Java19 module. Do not unload Java25 after loading R: module dependency handling
would unload R itself. This arrangement passed native package load and complete
CPU COMPSs submission/transfer/assembly smoke tests.

Installed R dependencies from CRAN into the isolated library:
Rcpp, RMVL, foreach, doParallel, testthat and their dependencies.

The library and executors were built from revision483ddee plus the two-line
`build-compat.patch` already required by the Rooster development installation.
It converts Rcpp Nullable values with `.get()` before construction. The existing
uncommitted source edits were not swept into the benchmark branch; the exact
build patch is supplied separately for reproducibility.

Build commands, in the isolated copy build-src:

    source ../env.sh
    cmake -S . -B cmake-build -DCMAKE_CUDA_ARCHITECTURES=80 -DCMAKE_BUILD_TYPE=Release
    cmake --build cmake-build -j4
    cp cmake-build/src/RCOMPSs.so src/RCOMPSs.so
    R CMD INSTALL --no-configure --library="$R_LIBS_USER" .
    cp cmake-build/aux/rcompss_* "$COMPSS_HOME/Runtime/scripts/system/adaptors/nio/pipers/"

PaRSEC uses the existing testing_dgemm binary under:
/home/abdullsm/exageostat_parsec_2025/exageostat-dev-gb24-gpu/build/hicma-x/dplasma/tests/.
Load intel/2022.3 and mkl/latest for its existing MKL ABI dependencies, then
preload the same system OpenBLAS as R. Loader binding logs confirm the GEMM CPU
symbol resolves to OpenBLAS. All four small CPU transpose checks passed.
GPU and large-case behavior are gated by the allocation's preflight checks.

Completed checks before submission readiness:
- RCOMPSs CPU tests:79 passed,4 GPU tests skipped,0 failures.
- Small full-output GEMM and disjoint output-region coverage checks passed.
- C++ helper compilation, all R/Python/shell syntax checks passed.
- COMPSs CPU submission, native worker execution, return and matrix assembly passed.
- PSS monitor detected the returned worker PID despite SSH launch.
- An independent64MiB allocation fixture was observed above60MiB PSS.

GPU results and figure correctness remain untested until the queued job starts.
