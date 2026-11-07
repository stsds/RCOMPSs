module use /sw/rl9c/modulefiles/compilers
module load R/4.6.1/gnu-12.2.0
module load java/19.0.1 cuda/12.4.1 cmake/3.28.4/gnu-11.3.1
export JAVA_HOME=/sw/rl9c/java/19.0.1/rl9_binary/jdk-19.0.1
export COMPSS_HOME=$HOME/software/rcompss-20261029/COMPSs
export CUDA_HOME=/sw/rl9g/cuda/12.4.1/rl9_binary
export CUDACXX=$CUDA_HOME/bin/nvcc
export CUDAHOSTCXX=$(command -v g++)
export PATH=$COMPSS_HOME/Runtime/scripts/user:$JAVA_HOME/bin:$PATH
export R_LIBS_USER=$HOME/software/rcompss-20261029/ibex-campaign/library
export R_LIBS=$R_LIBS_USER
export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:$COMPSS_HOME/Bindings/bindings-common/lib:$COMPSS_HOME/Bindings/RCOMPSs/dummy_extrae:$LD_LIBRARY_PATH
export RCM_COMPSs_TRACING=OFF CUDA_DEVICE_ORDER=PCI_BUS_ID
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
export PYTHONPATH=$HOME/software/rcompss-20261029/ibex-campaign/python${PYTHONPATH:+:$PYTHONPATH}
