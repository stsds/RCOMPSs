##########################################################################
# Copyright (c) 2025, King Abdullah University of Science and Technology
# All rights reserved.
# RCOMPSs is an R package provided by the STSDS group at KAUST
##########################################################################

add_library(RCOMPSs SHARED
  compssmodule.cpp
  RcppGpuLinalg.cpp
  RcppExports.cpp
)

add_subdirectory(core)
add_subdirectory(executor)
add_subdirectory(worker)
add_subdirectory(kernels)
add_subdirectory(adapters)

