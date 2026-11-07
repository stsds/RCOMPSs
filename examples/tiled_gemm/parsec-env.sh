export LD_LIBRARY_PATH=/opt/ecrc/cuda/11.6/lib64:/opt/ecrc/mkl/2020.0.166/mkl/lib/intel64:/opt/ecrc/intel-it/2019/compilers_and_libraries_2020.0.166/linux/compiler/lib/intel64_lin:/opt/ecrc/intelmpi/2018-update-1/compilers_and_libraries/linux/mpi/intel64/lib/release_mt:${LD_LIBRARY_PATH:-}
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
export CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=2
export LD_PRELOAD=/lib/x86_64-linux-gnu/libopenblas.so.0
export PARSEC_GEMM=$HOME/develop/parsec/exageostat-dev/build/hicma-x/dplasma/tests/testing_dgemm
