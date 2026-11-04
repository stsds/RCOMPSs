source "$HOME/software/rcompss-20261029/env.sh"
export R_LIBS_USER=$HOME/software/rcompss-20261029/tiled-gemm-optimization/library-after
export R_LIBS=$R_LIBS_USER:$COMPSS_HOME/Bindings/RCOMPSs/user_libs
export CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=1,2
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
export LD_LIBRARY_PATH=/opt/ecrc/cuda/11.6/lib64:/opt/ecrc/mkl/2020.0.166/mkl/lib/intel64:/opt/ecrc/intel-it/2019/compilers_and_libraries_2020.0.166/linux/compiler/lib/intel64_lin:/opt/ecrc/intelmpi/2018-update-1/compilers_and_libraries/linux/mpi/intel64/lib/release_mt:$LD_LIBRARY_PATH
export PARSEC_GEMM=$HOME/develop/parsec/exageostat-dev/build/hicma-x/dplasma/tests/testing_dgemm
