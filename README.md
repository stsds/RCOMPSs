What is RCOMPSs?
================

RCOMPSs is a programming model designed to simplify the parallel execution of R code. It enables users to develop applications as standard R scripts while easily identifying specific functions as tasks. The underlying COMPSs runtime automatically manages task dependencies, builds a data dependency graph, and dynamically schedules tasks across distributed computing resources. This abstraction allows efficient and scalable execution with minimal changes to the original R code, freeing users from the complexities of parallelization and resource management.


Vision of RCOMPSS
=================

RCOMPSs is the result of a collaborative effort betweenthe STSDS group at  KAUST (King Abdullah University of Science and Technology) and the Barcelona Supercomputing Center (BSC), driven by a shared vision to bring scalable, high-performance computing capabilities to the R programming ecosystem. The project aims to empower R users with seamless access to parallel and distributed computing without the need for extensive code rewriting or expertise in parallel programming. By integrating the task-based programming model of COMPSs into R, RCOMPSs enables researchers and practitioners to accelerate their data analysis, machine learning, and scientific computing workloads efficiently across multicore, cluster, and cloud environments. Our long-term vision is to make large-scale parallel computing accessible to the broader R community, fostering innovation in fields such as computational statistics, machine learning, bioinformatics, and climate science.


Installation
============

```bash
./install.sh <target_dir> <tracing>
```

Where:

- `target_dir`: Destination path where to install RCOMPSs
- `tracing`: Compile with tracing enabled or disabled (true | false)


References
==========
- [To be defined]

License
==========
- [To be defined]

Acknowledgement
==========
- Computer, Electrical and Mathematical Sciences and Engineering (CEMSE) Division, King Abdullah University of Science and Technology (KAUST), Thuwa, Saudi Arabia.
- Barcelona Supercomputing Center (BSC), Barcelona, Spain.
- [Other to be defined]

