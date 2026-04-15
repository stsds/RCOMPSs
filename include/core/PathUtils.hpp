/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file PathUtils.hpp
 * @brief Path and filename manipulation utilities
 * @version 1.0
 * @date 2025-01-XX
 */

#ifndef RCOMPSs_PATHUTILS_HPP
#define RCOMPSs_PATHUTILS_HPP

#include <string>

namespace RCOMPSs {
namespace core {

/**
 * @class PathUtils
 * @brief Path and filename manipulation utilities
 */
class PathUtils {
public:
  /**
   * @brief Extract serialization method from filepath
   * 
   * Replicates R logic: strsplit(basename(filepath), "-")[[1]][1]
   * Extracts the method prefix from filenames like: /path/to/qs-filenamexxxx
   * 
   * @param filepath Full file path
   * @return Serialization method string (e.g., "qs", "RMVL")
   */
  static std::string extractSerializationMethod(const std::string& filepath);
  
  /**
   * @brief Get basename from filepath
   * 
   * Replicates R's basename() function
   * 
   * @param filepath Full file path
   * @return Basename (filename with extension)
   */
  static std::string basename(const std::string& filepath);
  
  /**
   * @brief Build serialization filename for arguments
   * 
   * Replicates R logic: paste0(MASTER_WORKING_DIR, "/", ser_method, "-", arg_name, "_arg[", index, "]_", uid)
   * 
   * @param master_working_dir Master working directory path
   * @param ser_method Serialization method (e.g., "qs", "RMVL")
   * @param arg_name Argument name
   * @param index Argument index (0-based)
   * @param uid Unique ID string
   * @return Full filepath for serialized argument
   */
  static std::string buildArgumentFilename(const std::string& master_working_dir,
                                           const std::string& ser_method,
                                           const std::string& arg_name,
                                           int index,
                                           const std::string& uid);
  
  /**
   * @brief Build serialization filename for return values
   * 
   * Replicates R logic: paste0(MASTER_WORKING_DIR, "/", ser_method, "-", "ReturnValue_", uid)
   * 
   * @param master_working_dir Master working directory path
   * @param ser_method Serialization method (e.g., "qs", "RMVL")
   * @param uid Unique ID string
   * @return Full filepath for serialized return value
   */
  static std::string buildReturnValueFilename(const std::string& master_working_dir,
                                               const std::string& ser_method,
                                               const std::string& uid);
  
  /**
   * @brief Build typeArgs path
   * 
   * Replicates R logic: paste0(getwd(), "/", filename)
   * 
   * @param working_dir Current working directory
   * @param filename Filename
   * @return Full path string
   */
  static std::string buildTypeArgsPath(const std::string& working_dir, const std::string& filename);
};

} // namespace core
} // namespace RCOMPSs

#endif // RCOMPSs_PATHUTILS_HPP

