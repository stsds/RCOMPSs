RCOMPSs
=======

What is RCOMPSs?
----------------

RCOMPSs is a programming model designed to simplify the parallel execution of R code. It enables users to develop applications as standard R scripts while easily identifying specific functions as tasks. The underlying COMPSs runtime automatically manages task dependencies, builds a data dependency graph, and dynamically schedules tasks across distributed computing resources. This abstraction allows efficient and scalable execution with minimal changes to the original R code, freeing users from the complexities of parallelization and resource management.

Vision of RCOMPSs
-----------------

RCOMPSs is the result of a collaborative effort between the STSDS group at KAUST (King Abdullah University of Science and Technology) , the Barcelona Supercomputing Center (BSC) and Brightskies, driven by a shared vision to bring scalable, high-performance computing capabilities to the R programming ecosystem. The project aims to empower R users with seamless access to parallel and distributed computing without the need for extensive code rewriting or expertise in parallel programming. By integrating the task-based programming model of COMPSs into R, RCOMPSs enables researchers and practitioners to accelerate their data analysis, machine learning, and scientific computing workloads efficiently across multicore, cluster, and cloud environments. Our long-term vision is to make large-scale parallel computing accessible to the broader R community, fostering innovation in fields such as computational statistics, machine learning, bioinformatics, and climate science.

Installation
------------

RCOMPSs is installed as part of the COMPSs source installation by running the `install_rcompss.sh` script.

### Prerequisites

- A JDK must be available. Ensure that `JAVA_HOME` is set, or load an appropriate JDK module before installation.
- RCOMPSs requires several R package dependencies. These dependencies will also be installed automatically during the RCOMPSs installation process:
  - `Rcpp`, `RMVL`, `foreach`, `parallel` (included with base R), `doParallel`, `stringr`, `lobstr`, `proxy`, `lubridate`, `fields`, and `pryr`
- Gradle is recommended. Load an available Gradle module or install Gradle before proceeding.


### Install COMPSs runtime (Can be ignored if COMPSs is already installed)

```bash
./install_compss.sh [OPTIONS] [INSTALL_DIR]
```

`INSTALL_DIR` is where COMPSs will be installed (default: `$HOME/COMPSs_installation`) --- Please use absolute path.

### Selecting the COMPSs version

Before running the installer, edit the `TARBALL_NAME` and `TARBALL_URL` variables near
the start of `install_compss.sh`. They specify the COMPSs archive to download. For
example, the default configuration is:

```bash
local TARBALL_NAME="COMPSs_3.3.3_Trunk.tar.gz"
local TARBALL_URL="https://compss.bsc.es/~fconejer/${TARBALL_NAME}"
```

Set both values to the archive name and download URL for the COMPSs release you want
to install. Alternatively, use `--source-dir DIR` to install from an already extracted
COMPSs source directory without downloading an archive.

### Options

| Option | Description |
|--------|-------------|
| `--help`, `-h` | Show the help message |
| `--no-bashrc` | Don't modify `~/.bashrc` (print the env block instead) |
| `--source-dir DIR` | Use an already-extracted COMPSs source directory instead of downloading the tarball |
| `--r-libs DIR` | Path to the R user library directory (default: auto-detected from `~/R/`) |

### What the script does

1. Verifies `JAVA_HOME` and Gradle availability.
2. Sets Extrae MPI headers.
3. Downloads and extracts the COMPSs source (or uses the directory given via `--source-dir`).
4. Runs the COMPSs installer with support for the R bindings required by RCOMPSs.
5. Sets up passwordless SSH to localhost.
6. Writes the RCOMPSs environment to `~/.bashrc` (unless `--no-bashrc` is passed).

### Building RCOMPSs

To install RCOMPSs, run the `install_rcompss.sh` script with the target directory and the tracing flag:

```bash
./install_rcompss.sh <tracing>
```


| Parameter | Description |
|-----------|-------------|
| `tracing` | Whether to compile with Extrae tracing support (`true` or `false`) |

For example:

```bash
./install_rcompss.sh false
```

This script compiles the R binding, installs the required R packages, and deploys the RCOMPSs executor into the COMPSs runtime.


### Troubleshooting `libiconv`

If the linker reports that `libiconv` cannot be found, set the `LIBICONV_ROOT` environment variable to the libiconv installation directory and rerun the installer:

```bash
export LIBICONV_ROOT=/path/to/libiconv
./install_rcompss.sh  <tracing>


Examples
--------

**IMPORTANT:** Exporting an environment variable named `COMPSS_HOME` with the COMPSs installation path is mandatory. For example:

```bash
export COMPSS_HOME=/opt/COMPSs
```

### Addition

The `addition` example shows a simple R application parallelized with RCOMPSs.
It declares a task that adds two values, and then it is invoked with 4 inputs in order to get the accumulated value.

```bash
cd examples/addition
./run_addition_RCOMPSs.sh
```

The output are two files (stdout and stderr) containing the output from the execution.

### K-means

K-means is a widely used unsupervised learning algorithm that aims to partition a given dataset into $k$ clusters by minimizing intra-cluster variance. Given a dataset $\{x_1, x_2, \dots, x_n\} \subset \mathbb{R}^d$, the goal is to assign each data point to the cluster with the nearest centroid, the mean position of all points in a cluster, representing its geometric center in the feature space, thereby grouping similar points and keeping clusters as compact as possible. Formally, K-means seeks to minimize the Within-each-Cluster-Sum-of-Squares (WCSS):
```math
\underset{C}{\text{arg min}} \sum_{i=1}^k \sum_{x \in C_i} \|x - \mu_i\|^2,
```
where $\mu_i = \frac{1}{|C_i|} \sum_{x \in C_i} x$ is the centroid of cluster $C_i$.

Location:

```bash
cd examples/kmeans
```

Sequential execution:

```bash
./run_kmeans_R.sh
```

Parallel execution:

```bash
./run_kmeans_RCOMPSs.sh
```

Additionally, the `MN5_experiments` and `Shaheen_experiments` folders contain the scripts used to evaluate the Kmeans algorithm in both MN5 and Shaheen supercomputers.

### KNN

The K-Nearest Neighbors (KNN) classification algorithm is a supervised learning method for classification tasks. It is based on the principle that similar data points tend to be close to one another in the feature space. Let $\mathcal{D} = \{(x_1, y_1), (x_2, y_2), \dots, (x_n, y_n)\}$ denote a training dataset, where each $x_i \in \mathbb{R}^d$ is a feature vector and $y_i \in \mathcal{Y}$ is the corresponding label. Given a query point $x \in \mathbb{R}^d$, the algorithm computes the distance to all training points, typically using the Euclidean metric:
```math
d(x, x_i) = \|x - x_i\|.
```
It then selects the $k$ closest samples, $\mathcal{N}_k(x)$, and for classification tasks, assigns the most frequent label among them:
```math
\hat{y} = \arg\max_{y \in \mathcal{Y}} \sum_{i \in \mathcal{N}_k(x)} \mathbb{I}(y_i = y),
```
where $\mathbb{I}(\cdot)$ is the indicator function.

Location:

```bash
cd examples/knn
```

Sequential execution:

```bash
./run_knn_R.sh
```

Parallel execution:

```bash
./run_knn_RCOMPSs.sh
```

Additionally, the `MN5_experiments` and `Shaheen_experiments` folders contain the scripts used to evaluate the KNN algorithm in both MN5 and Shaheen supercomputers.

### Linear Regression

Linear regression models the relationship between a dependent variable $y$ and a set of independent variables $x_1, x_2, \dots, x_p$. For a given observation $i$, the model is expressed as:
```math
y_i = \beta_0 + \beta_1 x_{i1} + \beta_2 x_{i2} + \cdots + \beta_p x_{ip} + \varepsilon_i,
```
where $\beta_0$ is the intercept, $\beta_1, \dots, \beta_p$ are the regression coefficients, and $\varepsilon_i$ is the error term.

In vector form, this becomes:
```math
y_i = \mathbf{x}_i^\top \boldsymbol{\beta} + \boldsymbol\varepsilon_i,
```
where $\mathbf{x}_i = [1, x_{i1}, x_{i2}, \dots, x_{ip}]^\top$ includes the intercept term, and $\boldsymbol{\beta} = [\beta_0, \beta_1, \dots, \beta_p]^\top$ is the parameter vector. To estimate $\boldsymbol{\beta}$, the method of least squares minimizes the residual sum of squares:
```math
\min_{\boldsymbol{\beta}} \sum_{i=1}^n (y_i - \mathbf{x}_i^\top \boldsymbol{\beta})^2.
```

Let $\mathbf{X} \in \mathbb{R}^{n \times (p+1)}$ be the design matrix and $\mathbf{y} \in \mathbb{R}^n$ the response vector. The closed-form least squares solution is:
```math
\hat{\boldsymbol{\beta}} = (\mathbf{X}^\top \mathbf{X})^{-1} \mathbf{X}^\top \mathbf{y}.
```

Location:

```bash
cd examples/linear_regression
```

Sequential execution:

```bash
./run_linear_regression_R.sh
```

Parallel execution:

```bash
./run_linear_regression_RCOMPSs.sh
```

Additionally, the `MN5_experiments` and `Shaheen_experiments` folders contain the scripts used to evaluate the Linear Regression algorithm in both MN5 and Shaheen supercomputers.

### GPU (CUDA), cuBLAS, and cuSOLVER

These scripts need a COMPSs installation with GPU support, `COMPSS_HOME` set (see above), and a machine where COMPSs can schedule GPU workers. CUDA must be loaded as a module (e.g., `module load cuda`) or installed in the system path. Resource definitions live in `examples/gpu/test_resources_gpu.xml`.

Run GPU examples from that directory so the resource file resolves, or pass its absolute path to `--resources`.

```bash
cd examples/gpu
runcompss --lang=r --resources=test_resources_gpu.xml --tracing test_gpu_blas_solver_set1_main.R
```

**cuBLAS / cuSOLVER smoke tests** (`examples/gpu/`) — each set has a driver `test_gpu_blas_solver_setN_main.R` and a self-contained task module `test_gpu_blas_solver_setN_functions.R` registered with `task(..., filename=...)`. Task modules must stay self-contained (do not `source()` other R files inside them; COMPSs workers load only the given module path).

| Set | Driver | Covered R exports (high level) |
|-----|--------|--------------------------------|
| 1 | `test_gpu_blas_solver_set1_main.R` | DGEMM, DAXPY, DPOTRF (runs on 2 GPUs) |
| 2 | `test_gpu_blas_solver_set2_main.R` | DGEMV, DDOT, DNRM2 |
| 3 | `test_gpu_blas_solver_set3_main.R` | DSCAL, DTRMM, DTRSM |
| 4 | `test_gpu_blas_solver_set4_main.R` | DSYRK, DGETRF, DGETRS |
| 5 | `test_gpu_blas_solver_set5_main.R` | DPOTRS |

License
-------

- BSD 3-Clause License

Acknowledgement
---------------

- Computer, Electrical and Mathematical Sciences and Engineering (CEMSE) Division, King Abdullah University of Science and Technology (KAUST), Thuwal, Saudi Arabia.
- Barcelona Supercomputing Center (BSC), Barcelona, Spain.
- Brightskies:  a digital transformation enabler and market leader.
