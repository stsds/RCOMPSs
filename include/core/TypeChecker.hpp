/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file TypeChecker.hpp
 * @brief Type checking utilities for RCOMPSs
 * @version 1.0
 * @date 2025-01-XX
 */

#ifndef RCOMPSs_TYPECHECKER_HPP
#define RCOMPSs_TYPECHECKER_HPP

#include <string>
#include <vector>

namespace RCOMPSs {
namespace core {

/**
 * @class TypeChecker
 * @brief Utilities for checking R object types and classes
 */
class TypeChecker {
public:
  /**
   * @brief Check if an R object is a basic type that doesn't need serialization
   * 
   * Replicates R logic:
   * length(class(arg)) == 1 && length(arg) == 1 && (class(arg) %in% c("integer", "numeric", "character"))
   * 
   * @param r_class R class name (from class() function)
   * @param r_type R type name (from typeof() function)
   * @param length Length of the object
   * @return true if object is a basic type, false otherwise
   */
  static bool isBasicType(const std::string& r_class, const std::string& r_type, int length);
  
  /**
   * @brief Check if an R object is a future_object
   * 
   * Replicates R logic: length(class(obj)) == 1 && class(obj) == "future_object"
   * 
   * @param r_class R class name (from class() function)
   * @return true if object is a future_object, false otherwise
   */
  static bool isFutureObject(const std::string& r_class);
  
  /**
   * @brief Check if an R object is a future_object_path
   * 
   * Replicates R logic: length(class(obj)) == 1 && class(obj) == "future_object_path"
   * 
   * @param r_class R class name (from class() function)
   * @return true if object is a future_object_path, false otherwise
   */
  static bool isFutureObjectPath(const std::string& r_class);
  
  /**
   * @brief Check if an R object is a list
   * 
   * Replicates R logic: length(class(obj)) == 1 && class(obj) == "list"
   * 
   * @param r_class R class name (from class() function)
   * @return true if object is a list, false otherwise
   */
  static bool isList(const std::string& r_class);
};

} // namespace core
} // namespace RCOMPSs

#endif // RCOMPSs_TYPECHECKER_HPP

