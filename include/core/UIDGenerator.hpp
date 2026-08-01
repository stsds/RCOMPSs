/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file UIDGenerator.hpp
 * @brief Unique ID generator class for RCOMPSs
 * @version 1.0
 * @date 2025-01-XX
 */

 #ifndef RCOMPSs_UIDGENERATOR_HPP
 #define RCOMPSs_UIDGENERATOR_HPP
 
 #include <string>
 #include <chrono>
 #include <random>
 #include <mutex>
 
 namespace RCOMPSs {
 namespace core {
 
 /**
  * @class UIDGenerator
  * @brief Thread-safe unique ID generator
  * 
  * This class replicates the exact R logic from UID() function:
  * - Get current time (Sys.time())
  * - Format as YYYYMMDDHHMMSS (format(current_time, "%Y%m%d%H%M%S"))
  * - Generate 50 random chars from [a-z, A-Z, 0-9] (sample(c(letters, LETTERS, 0:9), 50, replace=TRUE))
  * - Combine: timestamp-randomstring (paste0(time_string, "-", random_string))
  */
 class UIDGenerator {
 private:
   static std::mutex mutex_;
   static std::random_device rd_;
   static std::mt19937 gen_;
   static std::uniform_int_distribution<> dis_;
   
 public:
   /**
    * @brief Generate a unique ID
    * 
    * Replicates exact R logic:
    *   current_time <- Sys.time()
    *   time_string <- format(current_time, "%Y%m%d%H%M%S")
    *   random_string <- paste0(sample(c(letters, LETTERS, 0:9), 50, replace = TRUE), collapse = "")
    *   return(paste0(time_string, "-", random_string))
    * 
    * @return Unique string ID (format: YYYYMMDDHHMMSS-randomstring)
    */
   static std::string generate();
 };
 
 } // namespace core
 } // namespace RCOMPSs
 
 #endif // RCOMPSs_UIDGENERATOR_HPP
 
 