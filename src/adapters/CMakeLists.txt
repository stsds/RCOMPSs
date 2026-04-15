##########################################################################
# Copyright (c) 2025, King Abdullah University of Science and Technology
# All rights reserved.
# RCOMPSs is an R package provided by the STSDS group at KAUST
##########################################################################

# Add adapter sources to RCOMPSs library
target_sources(RCOMPSs PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/RContextManager.cpp
)

