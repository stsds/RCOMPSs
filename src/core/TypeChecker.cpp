/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file TypeChecker.cpp
 * @brief Implementation of type checking utilities
 * @version 1.0
 * @date 2025-01-XX
 */

#include <core/TypeChecker.hpp>
#include <string>
#include <algorithm>

namespace RCOMPSs {
namespace core {

bool TypeChecker::isBasicType(const std::string& r_class, const std::string& r_type, int length) {
  
  // Check if length is 1
  if (length != 1) {
    return false;
  }
  
  if (r_class == "integer" || r_class == "numeric" || r_class == "character") {
    return true;
  }
  
  if (r_type == "integer" || r_type == "double" || r_type == "character") {
    return true;
  }
  
  return false;
}

bool TypeChecker::isFutureObject(const std::string& r_class) {
  return r_class == "future_object";
}

bool TypeChecker::isFutureObjectPath(const std::string& r_class) {
  return r_class == "future_object_path";
}

bool TypeChecker::isList(const std::string& r_class) {
  return r_class == "list";
}

} // namespace core
} // namespace RCOMPSs

