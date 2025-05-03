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

RCOMPSs is installed  as part of the COMPSs source installation by adding the `--rcompss` to the `buildlocal` command.

Please, check the [COMPSs installation instructions](https://compss-doc.readthedocs.io/en/latest/Sections/01_Installation/02_Building_from_sources.html)

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
./run_addition_RCOMPSs
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

License
-------

- BSD 3-Clause License

Acknowledgement
---------------

- Computer, Electrical and Mathematical Sciences and Engineering (CEMSE) Division, King Abdullah University of Science and Technology (KAUST), Thuwa, Saudi Arabia.
- Barcelona Supercomputing Center (BSC), Barcelona, Spain.
