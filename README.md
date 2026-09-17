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

RCOMPSs is installed on top of a COMPSs runtime. The recommended workflow is:

1. Install the operating-system prerequisites.
2. Install COMPSs with `install_compss.sh`.
3. Set `COMPSS_HOME` and load the COMPSs environment.
4. Install the RCOMPSs binding with `install_rcompss.sh`.
5. Run the validation example.

### Platform notes

RCOMPSs is intended for Linux systems. The commands below are suitable for clean
installation/portability tests on Ubuntu 22.04/24.04 and Red Hat Enterprise Linux
8/9. Package names can differ slightly between distributions and repositories.

> **COMPSs version note:** RCOMPSs relies on the Java and Gradle versions required
> by the selected COMPSs release. Current COMPSs documentation uses OpenJDK 21 and
> Gradle 8.7. If `install_compss.sh` is configured to install an older COMPSs
> release, use the Java/Gradle versions required by that release.

### Prerequisites

RCOMPSs/COMPSs requires a JDK, R, C/C++ build tools, CMake, MPI headers, SSH,
Boost, XML development headers, and the build dependencies required by COMPSs.
RCOMPSs also requires several R packages; they are installed automatically by
`install_rcompss.sh`:

- `Rcpp`, `RMVL`, `foreach`, `parallel` (included with base R), `doParallel`,
  `stringr`, `lobstr`, `proxy`, `lubridate`, `fields`, and `pryr`.

#### Ubuntu 22.04 / 24.04

```bash
sudo apt-get update
sudo apt-get install -y \
    ca-certificates git wget curl unzip \
    build-essential cmake pkg-config \
    libtool automake autoconf flex bison texinfo \
    graphviz xdg-utils csh gfortran \
    python3 python3-dev python3-pip \
    libboost-serialization-dev libboost-iostreams-dev \
    libxml2 libxml2-dev libgmp-dev libpapi-dev \
    openmpi-bin libopenmpi-dev \
    openssh-client openssh-server \
    r-base r-base-dev \
    openjdk-21-jdk
```

Set the JDK location:

```bash
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
```

If Gradle is not already available, install a compatible Gradle version. For
current COMPSs releases:

```bash
wget https://services.gradle.org/distributions/gradle-8.7-bin.zip \
    -O /tmp/gradle-8.7-bin.zip
sudo unzip -q /tmp/gradle-8.7-bin.zip -d /opt

export GRADLE_HOME=/opt/gradle-8.7
export PATH=${GRADLE_HOME}/bin:${PATH}
```

Check the basic toolchain before continuing:

```bash
java -version
gradle --version
R --version
cmake --version
mpicc --version
```

#### Red Hat Enterprise Linux 8 / 9

On RHEL, enable the repositories required for development packages on your
system, then install the corresponding dependencies. A typical setup is:

```bash
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y \
    ca-certificates git wget curl unzip \
    cmake pkgconf-pkg-config \
    libtool automake autoconf flex bison texinfo \
    graphviz xdg-utils tcsh gcc-gfortran \
    python3 python3-devel python3-pip \
    boost-devel libxml2 libxml2-devel \
    gmp-devel papi papi-devel \
    openmpi openmpi-devel \
    openssh-clients openssh-server \
    R R-devel \
    java-21-openjdk java-21-openjdk-devel
```

Depending on the RHEL repository configuration, some packages (especially R,
PAPI, or development packages) may require additional enabled repositories.
Use the package names available on the target RHEL 8/9 installation.

Set the JDK location:

```bash
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
```

Install a Gradle version compatible with the selected COMPSs release and ensure
that `gradle` is available in `PATH`.

### Install COMPSs runtime

This step can be skipped if a compatible COMPSs installation is already
available.

```bash
./install_compss.sh [OPTIONS] [INSTALL_DIR]
```

`INSTALL_DIR` is where COMPSs will be installed (default:
`$HOME/COMPSs_installation`). Use an absolute path.

For example:

```bash
./install_compss.sh /opt/COMPSs
```

If `/opt/COMPSs` requires elevated privileges, either choose a user-writable
installation directory or run the installation with the required permissions.

#### Selecting the COMPSs version

Before running the installer, edit the `TARBALL_NAME` and `TARBALL_URL`
variables near the start of `install_compss.sh`. They specify the COMPSs archive
to download. For example, the current repository configuration contains:

```bash
local TARBALL_NAME="COMPSs_3.3.3_Trunk.tar.gz"
local TARBALL_URL="https://compss.bsc.es/~fconejer/${TARBALL_NAME}"
```

Set both values to the archive name and download URL for the COMPSs release you
want to install. Alternatively, use `--source-dir DIR` to install from an
already extracted COMPSs source directory without downloading an archive.

#### `install_compss.sh` options

| Option | Description |
|--------|-------------|
| `--help`, `-h` | Show the help message |
| `--no-bashrc` | Do not modify `~/.bashrc`; print the environment block instead |
| `--source-dir DIR` | Use an already-extracted COMPSs source directory instead of downloading the tarball |
| `--r-libs DIR` | Path to the R library directory (default: auto-detected from R) |

The script:

1. Verifies `JAVA_HOME` and checks Gradle availability.
2. Detects the MPI headers used by Extrae.
3. Downloads and extracts the COMPSs source, or uses `--source-dir`.
4. Installs COMPSs with the R binding enabled.
5. Applies the runtime JVM workaround used by the current installer when needed.
6. Checks passwordless SSH to `localhost`.
7. Configures the shell environment in `~/.bashrc` unless `--no-bashrc` is used.

### Set the COMPSs environment

`COMPSS_HOME` **must be set before running `install_rcompss.sh`**.

For example:

```bash
export COMPSS_HOME=/opt/COMPSs
source ${COMPSS_HOME}/compssenv
```

If `install_compss.sh` was allowed to update `~/.bashrc`, opening a new shell
(or running `source ~/.bashrc`) should set these variables automatically.

Verify the runtime:

```bash
echo "${COMPSS_HOME}"
runcompss --version
```

### Build and install RCOMPSs

Run:

```bash
./install_rcompss.sh false
```

The argument controls Extrae tracing:

| Parameter | Description |
|-----------|-------------|
| `false` | Build RCOMPSs without Extrae tracing |
| `true` | Build RCOMPSs with Extrae tracing |

The script installs the required R packages, builds the R package, compiles the
RCOMPSs worker/executor, and deploys the required files into the COMPSs runtime.

### Validate the installation

First verify that the R package can be loaded:

```bash
Rscript -e 'library(RCOMPSs); cat("RCOMPSs loaded successfully\n")'
```

Then run the small addition example:

```bash
cd examples/addition
./run_addition_RCOMPSs.sh
```

The example should complete without installation/runtime errors. Inspect the
generated standard-output and standard-error files if the example script
redirects the COMPSs output.

### Docker: clean installation testing

Docker is useful for testing RCOMPSs from a completely clean operating-system
image. Docker is **not required** for a normal RCOMPSs installation.

For example, from the host:

```bash
docker run --rm -it ubuntu:24.04 bash
```

A minimal Docker image normally does not contain `sudo`, systemd, SSH, R, Java,
or development tools. Commands inside the default container are usually run as
`root`, so omit `sudo` from the Ubuntu prerequisite commands above.

After installing `openssh-server`, start SSH manually because a minimal Docker
container normally does not run systemd:

```bash
mkdir -p /run/sshd
/usr/sbin/sshd

mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
ssh-keyscan -H localhost >> ~/.ssh/known_hosts

ssh -o BatchMode=yes localhost true
```

The final command should return successfully without prompting for a password.
This is needed because COMPSs launches local workers through SSH.

For Red Hat-family container pre-testing, Red Hat Universal Base Images can be
used:

```bash
docker run --rm -it registry.access.redhat.com/ubi8/ubi bash
docker run --rm -it registry.access.redhat.com/ubi9/ubi bash
```

UBI 8/9 is useful for dependency and build compatibility testing, but it should
not be reported as a full RHEL 8/9 validation. For a strict RHEL compatibility
claim, repeat the final installation and validation on actual RHEL 8 and/or
RHEL 9 systems or virtual machines.

### Troubleshooting: `libiconv`

If the linker reports that `libiconv` cannot be found, set `LIBICONV_ROOT` to
the libiconv installation directory and rerun the installer:

```bash
export LIBICONV_ROOT=/path/to/libiconv
./install_rcompss.sh false
```

Examples
--------

**IMPORTANT:** `COMPSS_HOME` must point to the COMPSs installation. If it is
not already set in the current shell, set it before running the examples:

```bash
export COMPSS_HOME=/opt/COMPSs
source ${COMPSS_HOME}/compssenv
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
