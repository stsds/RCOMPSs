/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file StringUtils.hpp
 * @brief String manipulation utilities for RCOMPSs
 * @version 1.0
 * @date 2025-01-XX
 */

#ifndef RCOMPSs_STRINGUTILS_HPP
#define RCOMPSs_STRINGUTILS_HPP

#include <string>
#include <vector>

namespace RCOMPSs {
namespace core {

/**
 * @class StringUtils
 * @brief String manipulation and building utilities
 */
class StringUtils {
public:
  /**
   * @brief Build argument names for variable arguments
   * 
   * Replicates R logic: paste0(paste0(f_name, "___"), 1:length(arguments))
   * Generates names like: "functionName___1", "functionName___2", etc.
   * 
   * @param function_name Function name
   * @param count Number of arguments
   * @return Vector of argument names
   */
  static std::vector<std::string> buildVariableArgumentNames(const std::string& function_name, int count);
  
  /**
   * @brief Build return value name
   * 
   * Replicates R logic: paste0(ser_method, "-RETURN_VALUE")
   * 
   * @param ser_method Serialization method (e.g., "qs", "RMVL")
   * @return Return value name string
   */
  static std::string buildReturnValueName(const std::string& ser_method);
  
  /**
   * @brief Build register marker name
   * 
   * Replicates R logic: paste0("registered_", f_name)
   * 
   * @param function_name Function name
   * @return Register marker string
   */
  static std::string buildRegisterMarker(const std::string& function_name);
  
  /**
   * @brief Build constraint string from key-value pairs
   * 
   * Builds constraint string in format: key:value;key2:value2;
   * Examples:
   *   - computing_units:2;
   *   - processors:[{ProcessorType: CPU, ComputingUnits: 1}, {ProcessorType: GPU, ComputingUnits: 1}];
   * 
   * @param constraints Named list of constraints (key-value pairs)
   * @return Constraint string in COMPSs format
   */
  static std::string buildConstraintString(const std::vector<std::pair<std::string, std::string>>& constraints);
};

} // namespace core
} // namespace RCOMPSs

#endif // RCOMPSs_STRINGUTILS_HPP

