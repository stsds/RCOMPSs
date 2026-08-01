/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file PathUtils.cpp
 * @brief Implementation of path and filename manipulation utilities
 * @version 1.0
 * @date 2025-01-XX
 */

#include <core/PathUtils.hpp>
#include <string>
#include <algorithm>

namespace RCOMPSs {
namespace core {

std::string PathUtils::basename(const std::string& filepath) {
  // Find the last directory separator
  size_t last_slash = filepath.find_last_of("/\\");
  if (last_slash == std::string::npos) {
    // No directory separator, return the whole path
    return filepath;
  }
  // Return everything after the last separator
  return filepath.substr(last_slash + 1);
}

std::string PathUtils::extractSerializationMethod(const std::string& filepath) {
 // Get basename first
  std::string filename = basename(filepath);
  
  // Find the first '-' character
  size_t dash_pos = filename.find('-');
  if (dash_pos == std::string::npos) {
    // No dash found, return empty string (shouldn't happen in normal usage)
    return "";
  }
  
  // Return everything before the first dash
  return filename.substr(0, dash_pos);
}

std::string PathUtils::buildArgumentFilename(const std::string& master_working_dir,
                                              const std::string& ser_method,
                                              const std::string& arg_name,
                                              int index,
                                              const std::string& uid) {
  // Use the provided serialization method to build filename prefix
  // This ensures the filename matches the actual serialization format
  std::string method = ser_method.empty() ? "cpp" : ser_method;
  std::string result = master_working_dir;
  if (!result.empty() && result.back() != '/') {
    result += "/";
  }
  result += method;
  result += "-";
  result += arg_name;
  result += "_arg[";
  result += std::to_string(index);
  result += "]_";
  result += uid;
  return result;
}

std::string PathUtils::buildReturnValueFilename(const std::string& master_working_dir,
                                                 const std::string& ser_method,
                                                 const std::string& uid) {
  // Use the provided serialization method to build filename prefix
  // This ensures the filename matches the actual serialization format
  std::string method = ser_method.empty() ? "cpp" : ser_method;
  std::string result = master_working_dir;
  if (!result.empty() && result.back() != '/') {
    result += "/";
  }
  result += method;
  result += "-ReturnValue_";
  result += uid;
  return result;
}

std::string PathUtils::buildTypeArgsPath(const std::string& working_dir, const std::string& filename) {
  std::string result = working_dir;
  if (!result.empty() && result.back() != '/') {
    result += "/";
  }
  result += filename;
  return result;
}

} // namespace core
} // namespace RCOMPSs

