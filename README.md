# RCOMPSs

## Description

RCOMPSs is a programming model that simplifies the parallel execution of R code. It allows users to write applications as standard R scripts, simply marking certain functions as tasks. The underlying COMPSs runtime then automatically manages dependencies between tasks, creates a data dependency graph, and dynamically schedules tasks across distributed resources. This enables efficient and scalable execution with minimal modifications to the original R code, abstracting away the complexities of parallelization.

## Installation steps

```bash
./install.sh <target_dir> <tracing>
```

Where:

- `target_dir`: Destination path where to install RCOMPSs
- `tracing`: Compile with tracing enabled or disabled (true | false)

## Citation

- [To be defined]

## License

- [To be defined]

## Acknowledgement

- Computer, Electrical and Mathematical Sciences and Engineering (CEMSE) Division, King Abdullah University of Science and Technology (KAUST).
- Barcelona Supercomputing Center (BSC),
- [Other to be defined]

## Contact

- Xiran Zhang <xiran.zhang@kaust.edu.sa>
- Javier Conejero <javier.conejero@bsc.es>
