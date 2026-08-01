/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file TypeMapper.cpp
 * @brief Implementation of type mapping utilities
 * @version 1.0
 * @date 2025-01-XX
 */

#include <core/TypeMapper.hpp>
#include <string>

namespace RCOMPSs {
namespace core {

int TypeMapper::mapType(const std::string& r_type) {
  if (r_type == "logical") {
    return 0;
  } else if (r_type == "CHAR") {
    return 1;
  } else if (r_type == "BYTE") {
    return 2;
  } else if (r_type == "SHORT") {
    return 3;
  } else if (r_type == "integer") {
    return 4;
  } else if (r_type == "double") {
    return 7;
  } else if (r_type == "character") {
    return 8;
  } else {
    // Default: FILE type
    return 10;
  }
}

} // namespace core
} // namespace RCOMPSs

