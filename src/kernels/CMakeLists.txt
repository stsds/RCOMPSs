##########################################################################
# Copyright (c) 2025, King Abdullah University of Science and Technology
# All rights reserved.
# RCOMPSs is an R package provided by the STSDS group at KAUST
##########################################################################

# Add kernel sources to RCOMPSs library
target_sources(RCOMPSs PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/ContextManager.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/RunContext.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/MemoryHandler.cpp
)

# Add CUDA subdirectory if CUDA is enabled
if (USE_CUDA)
    add_subdirectory(cuda)
endif()

