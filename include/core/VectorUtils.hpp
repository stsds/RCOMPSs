/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file VectorUtils.hpp
 * @brief Vector initialization utilities for RCOMPSs
 * @version 1.0
 * @date 2025-01-XX
 */

#ifndef RCOMPSs_VECTORUTILS_HPP
#define RCOMPSs_VECTORUTILS_HPP

#include <vector>
#include <string>

namespace RCOMPSs {
namespace core {

/**
 * @class VectorUtils
 * @brief Vector initialization and manipulation utilities
 */
class VectorUtils {
public:
  /**
   * @brief Create integer vector filled with zeros
   * 
   * Replicates R logic: rep(0L, length = count)
   * 
   * @param count Length of vector
   * @return Vector of integers filled with 0
   */
  static std::vector<int> repInteger(int value, int count);
  
  /**
   * @brief Create string vector filled with a value
   * 
   * Replicates R logic: rep(value, length = count)
   * 
   * @param value String value to repeat
   * @param count Length of vector
   * @return Vector of strings filled with value
   */
  static std::vector<std::string> repString(const std::string& value, int count);
  
  /**
   * @brief Concatenate integer vector with a value
   * 
   * Replicates R logic: c(vector, value)
   * 
   * @param vec Input vector
   * @param value Value to append
   * @return New vector with value appended
   */
  static std::vector<int> concatInteger(const std::vector<int>& vec, int value);
  
  /**
   * @brief Concatenate string vector with a value
   * 
   * Replicates R logic: c(vector, value)
   * 
   * @param vec Input vector
   * @param value Value to append
   * @return New vector with value appended
   */
  static std::vector<std::string> concatString(const std::vector<std::string>& vec, const std::string& value);
};

} // namespace core
} // namespace RCOMPSs

#endif // RCOMPSs_VECTORUTILS_HPP

