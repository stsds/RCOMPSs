RCOMPSs
=======

What is RCOMPSs?
----------------

RCOMPSs is a programming model designed to simplify the parallel execution of R code. It enables users to develop applications as standard R scripts while easily identifying specific functions as tasks. The underlying COMPSs runtime automatically manages task dependencies, builds a data dependency graph, and dynamically schedules tasks across distributed computing resources. This abstraction allows efficient and scalable execution with minimal changes to the original R code, freeing users from the complexities of parallelization and resource management.

Vision of RCOMPSs
-----------------

RCOMPSs is the result of a collaborative effort between the STSDS group at KAUST (King Abdullah University of Science and Technology) and the Barcelona Supercomputing Center (BSC), driven by a shared vision to bring scalable, high-performance computing capabilities to the R programming ecosystem. The project aims to empower R users with seamless access to parallel and distributed computing without the need for extensive code rewriting or expertise in parallel programming. By integrating the task-based programming model of COMPSs into R, RCOMPSs enables researchers and practitioners to accelerate their data analysis, machine learning, and scientific computing workloads efficiently across multicore, cluster, and cloud environments. Our long-term vision is to make large-scale parallel computing accessible to the broader R community, fostering innovation in fields such as computational statistics, machine learning, bioinformatics, and climate science.

Installation
------------

RCOMPSs is installed from the COMPSs installation from source code adding `--rcompss` to the `buildlocal` command.

Please, check the [COMPSs installation instructions](https://compss-doc.readthedocs.io/en/latest/Sections/01_Installation/02_Building_from_sources.html)

Examples
--------

**IMPORTANT:** It is mandatory to install COMPSs before running any of the examples.

**IMPORTANT 2:** It is mandatory to export an environment variable named `COMPSS_HOME` with the COMPSs installation path. For example:

```bash
export COMPSS_HOME=/opt/COMPSs
```

### Addition

The `addition` example shows a simple R application parallelized with RCOMPSs.
It declares a task that adds two values, and then it is invoked with 4 inputs in order to get the accumulated value.

```bash
cd examples/addition
./run_addition_RCOMPSs
```

The output are two files (stdout and stderr) containing the output from the execution.

### K-means

TBD: Description.

Location:

```bash
cd examples/kmeans
```

Sequential execution:

```bash
./run_kmeansn_R.sh
```

Parallel execution:

```bash
./run_kmeans_RCOMPSs.sh
```

Additionally, the `MN5_experiments` and `Shaheen_experiments` folders contain the scripts used to evaluate the Kmeans algorithm in both MN5 and Shaheen supercomputers.

### KNN

TBD: Description.

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

TBD: Description.

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

License
-------

- BSD 3-Clause License

Acknowledgement
---------------

- Computer, Electrical and Mathematical Sciences and Engineering (CEMSE) Division, King Abdullah University of Science and Technology (KAUST), Thuwa, Saudi Arabia.
- Barcelona Supercomputing Center (BSC), Barcelona, Spain.
