/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file StringUtils.cpp
 * @brief Implementation of string manipulation utilities
 * @version 1.0
 * @date 2025-01-XX
 */

#include <core/StringUtils.hpp>
#include <string>
#include <vector>

namespace RCOMPSs {
namespace core {

std::vector<std::string> StringUtils::buildVariableArgumentNames(const std::string& function_name, int count) {
  // Generates: "functionName___1", "functionName___2", ..., "functionName___N"
  std::vector<std::string> result;
  result.reserve(count);
  
  std::string prefix = function_name + "___";
  for (int i = 1; i <= count; ++i) {
    result.push_back(prefix + std::to_string(i));
  }
  
  return result;
}

std::string StringUtils::buildReturnValueName(const std::string& ser_method) {
  return ser_method + "-RETURN_VALUE";
}

std::string StringUtils::buildRegisterMarker(const std::string& function_name) {
  return "registered_" + function_name;
}

std::string StringUtils::buildConstraintString(const std::vector<std::pair<std::string, std::string>>& constraints) {
  // Build constraint string in format: key:value;key2:value2;
  // Examples:
  //   - computing_units:2;
  //   - processors:[{ProcessorType: CPU, ComputingUnits: 1}, {ProcessorType: GPU, ComputingUnits: 1}];
  // Note: Always ends with semicolon
  
  if (constraints.empty()) {
    return "";
  }
  
  std::string result;
  for (size_t i = 0; i < constraints.size(); ++i) {
    result += constraints[i].first + ":" + constraints[i].second + ";";
  }
  
  return result;
}

} // namespace core
} // namespace RCOMPSs

