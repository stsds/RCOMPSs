##########################################################################
# Copyright (c) 2025, King Abdullah University of Science and Technology
# All rights reserved.
# RCOMPSs is an R package provided by the STSDS group at KAUST
##########################################################################

# Add CUDA source files to RCOMPSs library
target_sources(RCOMPSs PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/CudaLibraryWrappers.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/CudaMemoryKernels.cu
  ${CMAKE_CURRENT_SOURCE_DIR}/CudaVectorKernels.cu
)

# Set CUDA properties for the CUDA source files
set_source_files_properties(
  ${CMAKE_CURRENT_SOURCE_DIR}/CudaMemoryKernels.cu
  ${CMAKE_CURRENT_SOURCE_DIR}/CudaVectorKernels.cu
  PROPERTIES
  LANGUAGE CUDA
)

