# RCOMPSs

RCOMPSs is an R binding for the COMPSs task-based runtime. It lets you keep an R script as the application entry point, mark selected functions as tasks, and delegate dependency tracking, scheduling, and worker execution to COMPSs.

This repository contains more than the R package itself. It includes:

- the user-facing R API in `R/`
- the native COMPSs bridge in `src/`
- worker-side executor and piper scripts in `aux/`
- sample and benchmark applications in `examples/`

## What Is In The Package

From the source tree, the public interface is centered on these functions:

- `task()`: wraps an R function so calls are submitted to COMPSs instead of executed locally
- `compss_start()`: starts the runtime and records the master working directory
- `compss_wait_on()`: materializes task results on the master
- `compss_barrier()`: waits for submitted tasks
- `compss_stop()`: stops the runtime
- `extrae_ini()`, `extrae_emit_event()`, `extrae_flu()`, `extrae_fin()`: optional tracing hooks

Internally, the package uses:

- `src/compssmodule.cpp` to call COMPSs runtime functions such as runtime start/stop, task submission, barriers, and file synchronization
- `R/utils.R` to decorate R functions, map argument types, and serialize non-scalar values
- `aux/executor.R`, `aux/piper_worker.R`, and `aux/r_piper.sh` to run R tasks on COMPSs workers

## Execution Model

The source code shows this workflow:

1. Call `compss_start()`.
2. Wrap task functions with `task(f, "file.R", ...)`.
3. Invoke the decorated functions to submit tasks.
4. Use `compss_wait_on()` or `compss_barrier()` when synchronization is needed.
5. Call `compss_stop()` when the application finishes.

Important behavior visible in the implementation:

- `compss_start()` must be called before `task()`, because `task()` expects `MASTER_WORKING_DIR` to exist.
- The `filename` passed to `task()` is used to build the worker-side module path, and workers later `source()` that file before calling the task function.
- Basic scalar types are passed directly. Non-scalar objects are serialized to files and submitted as COMPSs file parameters.
- The code supports `RMVL` and `qs` serialization backends through the `ser_method` argument.

## Minimal Example

This is the pattern used in [`examples/addition/addition.R`](./examples/addition/addition.R):

```r
library(RCOMPSs)
source("add.R")

compss_start()

add_task <- task(
  add,
  "add.R",
  return_value = TRUE,
  ser_method = c("RMVL", "RMVL")
)

x <- add_task(4, 5)
y <- add_task(6, 7)
z <- add_task(x, y)

z <- compss_wait_on(z)
print(z)

compss_stop()
```

The default task return type is a future-like object that stores the output file path. `compss_wait_on()` resolves either a single future, a list of futures, or a vector of future paths.

## Installation Model

This repository is structured as an R package, but it is not a standalone CRAN-style package. The installation flow is coupled to a COMPSs deployment.

### Prerequisites

Install COMPSs before installing this binding. Its installation must provide:

```text
$COMPSS_HOME/Bindings/bindings-common/include
$COMPSS_HOME/Bindings/bindings-common/lib
$COMPSS_HOME/Runtime/scripts/system/adaptors/nio/pipers
```

The host also needs R with development headers, a C/C++ compiler, and a JDK. Set `JAVA_HOME` to that JDK.

The installation target must be `$COMPSS_HOME/Bindings/RCOMPSs`. To install against a particular COMPSs version, set `COMPSS_HOME` to that version's installation directory.

The `install.sh` script:

- rewrites `src/Makevars` with COMPSs, Java, and tracing include/library paths
- builds the package with `R CMD build`
- installs it into a binding-local `user_libs` directory with `R CMD INSTALL`
- deploys worker-side scripts into the COMPSs runtime piper adaptor directory
- installs a dummy Extrae library when tracing is disabled

### Install

From the repository root:

```bash
export COMPSS_HOME=/path/to/COMPSs
source "$COMPSS_HOME/compssenv"
export JAVA_HOME=/path/to/jdk

target_dir="$COMPSS_HOME/Bindings/RCOMPSs"
R_LIBS_USER="$target_dir/user_libs" \
  ./install.sh --compss-home "$COMPSS_HOME" "$target_dir" false
```

The final argument enables (`true`) or disables (`false`) Extrae tracing. Use `false` unless the COMPSs installation includes Extrae development files.

`--compss-home` makes the selected COMPSs version explicit. When it is omitted, the installer derives the COMPSs root from `target_dir` for backwards compatibility.

To clone, build, and use a COMPSs branch or tag in one command, provide a new source directory and installation directory:

```bash
compss_source=/path/to/COMPSs-source
compss_home=/path/to/COMPSs-install
target_dir="$compss_home/Bindings/RCOMPSs"

R_LIBS_USER="$target_dir/user_libs" \
  ./install.sh --compss-home "$compss_home" \
  --compss-source "$compss_source" \
  --compss-version <tag-or-branch> \
  "$target_dir" false
```

This uses the official `bsc-wdc/compss` repository, fetches its submodules, and runs COMPSs' `builders/buildlocal`. Use `--compss-repo <url>` to select a fork or mirror. The source and installation directories must not already exist.

Before cloning, the installer checks for the source-build tools required by COMPSs, including `git`, `wget`, `mvn`, a JDK, compiler/autotools, and Python. It also checks RCOMPSs prerequisites (`R`, `Rscript`, a JDK, and a C/C++ build toolchain) for both installation paths. Missing requirements are reported together before downloading or building anything. The output gives package-manager-neutral guidance; install the corresponding capabilities using your distribution's package manager.

The installer builds the package, installs its R dependencies into `$target_dir/user_libs`, deploys the worker scripts, and updates `src/Makevars` with the selected COMPSs and Java paths.

### Runtime environment and verification

Before running an RCOMPSs application:

```bash
source "$COMPSS_HOME/compssenv"
export JAVA_HOME=/path/to/jdk
export R_LIBS_USER="$COMPSS_HOME/Bindings/RCOMPSs/user_libs${R_LIBS_USER:+:$R_LIBS_USER}"
export LD_LIBRARY_PATH="$JAVA_HOME/lib/server:$COMPSS_HOME/Bindings/bindings-common/lib:$COMPSS_HOME/Bindings/RCOMPSs/dummy_extrae${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

If loading `RCOMPSs` reports a missing `GLIBCXX_*` symbol, start R with the newer `libstdc++.so.6` required by the COMPSs native libraries preloaded. Obtain it from the compiler toolchain used to build COMPSs, then set:

```bash
export LD_PRELOAD=/path/to/compatible/libstdc++.so.6${LD_PRELOAD:+:$LD_PRELOAD}
```

Verify the installation before running an example:

```bash
Rscript -e 'library(RCOMPSs); cat("RCOMPSs", as.character(packageVersion("RCOMPSs")), "loaded\\n")'
runcompss --version
```

If package loading fails because of an incompatible personal R library, run the installer with `R_ENVIRON_USER=/dev/null` and `R_LIBS_USER` set to the binding's `user_libs` directory.

## Repository Layout

```text
R/                High-level R API and serialization logic
src/              Rcpp bridge to COMPSs and Extrae
aux/              Worker launchers, executors, dummy Extrae, sample XML files
examples/         End-to-end applications, benchmarks, launcher scripts
man/              Generated R documentation
tests/            Minimal testthat scaffold
install.sh        COMPSs-side installation entry point
```

## Examples

The bundled examples fall into two groups: small API demonstrations and larger benchmark-style applications.

### Small Demonstrations

- `examples/addition`: the smallest end-to-end task example, including `run_addition_RCOMPSs.sh`
- `examples/standardization`: a compact example that chains three tasks and mixes `RMVL` and `qs` serialization

### Larger Applications

- `examples/kmeans`: fragmented K-means with sequential and RCOMPSs launchers, plus comparison scripts and cluster launchers for MN5 and Shaheen
- `examples/knn`: fragmented KNN classification with sequential and RCOMPSs launchers, plus comparison scripts and cluster launchers
- `examples/linear_regression`: fragmented linear regression and prediction workflow with sequential and RCOMPSs launchers, plus comparison scripts and cluster launchers
- `examples/MCMC`: multiple-chain MCMC example with comparison scripts for base parallelism, `future`, and RCOMPSs

Typical entry points are:

```bash
cd examples/addition
./run_addition_RCOMPSs.sh
```

```bash
cd examples/kmeans
./run_kmeans_R.sh
./run_kmeans_RCOMPSs.sh
```

```bash
cd examples/knn
./run_knn_R.sh
./run_knn_RCOMPSs.sh
```

```bash
cd examples/linear_regression
./run_linear_regression_R.sh
./run_linear_regression_RCOMPSs.sh
```

## Example Dependencies

The binding declares `Rcpp`, `RMVL`, `foreach`, `parallel`, and `doParallel`. The source also uses `qs` as a serialization backend, and the installer provisions additional runtime dependencies for the worker scripts and examples.

Some examples require additional packages beyond the core binding. From the example sources, these include packages such as:

- `qs`
- `caret`
- `ggplot2`
- `future`
- `future.apply`
- `furrr`
- `mirai`
- `bigmemory`
- `proxy`

## Notes From The Current Source

- `task()` supports ordinary function signatures and a pure `...` signature, but explicitly rejects functions that mix named formals with `...`.
- Return values are modeled as a single COMPSs output object per task call.
- Worker execution is file-based: task arguments that are not simple scalars are serialized before submission and deserialized on the worker.
- The worker implementation preloads `RCOMPSs` and uses a piper-based executor model under `aux/`.

## License

BSD 3-Clause License

## Acknowledgements

The repository headers and existing project materials identify the work as part of the STSDS group at KAUST, with COMPSs integration tied to the Barcelona Supercomputing Center.
