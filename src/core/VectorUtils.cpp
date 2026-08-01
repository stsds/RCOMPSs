/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file VectorUtils.cpp
 * @brief Implementation of vector initialization utilities
 * @version 1.0
 * @date 2025-01-XX
 */

#include <core/VectorUtils.hpp>
#include <vector>
#include <string>

namespace RCOMPSs {
namespace core {

std::vector<int> VectorUtils::repInteger(int value, int count) {
  std::vector<int> result(count, value);
  return result;
}

std::vector<std::string> VectorUtils::repString(const std::string& value, int count) {
  std::vector<std::string> result(count, value);
  return result;
}

std::vector<int> VectorUtils::concatInteger(const std::vector<int>& vec, int value) {
  std::vector<int> result = vec;
  result.push_back(value);
  return result;
}

std::vector<std::string> VectorUtils::concatString(const std::vector<std::string>& vec, const std::string& value) {
  std::vector<std::string> result = vec;
  result.push_back(value);
  return result;
}

} // namespace core
} // namespace RCOMPSs

