/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file TypeMapper.hpp
 * @brief Type mapping utilities for RCOMPSs
 * @version 1.0
 * @date 2025-01-XX
 */

#ifndef RCOMPSs_TYPEMAPPER_HPP
#define RCOMPSs_TYPEMAPPER_HPP

#include <string>

namespace RCOMPSs {
namespace core {

/**
 * @class TypeMapper
 * @brief Maps R types to COMPSs type numbering system
 * 
 * Replicates the R parType_mapping function logic:
 * switch(typeof(arg),
 *   "logical" = 0L,
 *   "CHAR" = 1L,
 *   "BYTE" = 2L,
 *   "SHORT" = 3L,
 *   "integer" = 4L,
 *   "double" = 7L,
 *   "character" = 8L,
 *   10L # FILE
 * )
 */
class TypeMapper {
public:
  /**
   * @brief Map R type string to COMPSs type number
   * 
   * @param r_type R type string (e.g., "logical", "integer", "double", "character")
   * @return COMPSs type number (0, 1, 2, 3, 4, 7, 8, or 10 for FILE)
   */
  static int mapType(const std::string& r_type);
};

} // namespace core
} // namespace RCOMPSs

#endif // RCOMPSs_TYPEMAPPER_HPP

