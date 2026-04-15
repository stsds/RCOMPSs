
##########################################################################
# Copyright (c) 2023, King Abdullah University of Science and Technology
# All rights reserved.
# RCOMPSs is an R package provided by the STSDS group at KAUST
##########################################################################

target_sources(RCOMPSs PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/PathUtils.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Serialization.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/StringUtils.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/TaskDecorator.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/TypeChecker.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/TypeMapper.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/UIDGenerator.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/VectorUtils.cpp
)