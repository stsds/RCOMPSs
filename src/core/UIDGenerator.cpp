/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file UIDGenerator.cpp
 * @brief Implementation of unique ID generator
 * @version 1.0
 * @date 2025-01-XX
 */

 #include <core/UIDGenerator.hpp>
 #include <sstream>
 #include <iomanip>
 #include <ctime>
 
 namespace RCOMPSs {
 namespace core {
 
 // Static member initialization
 std::mutex UIDGenerator::mutex_;
 std::random_device UIDGenerator::rd_;
 std::mt19937 UIDGenerator::gen_(rd_());
 std::uniform_int_distribution<> UIDGenerator::dis_(0, 61);
 
 std::string UIDGenerator::generate() {
   std::lock_guard<std::mutex> lock(mutex_);
   
   // Step 1: Get current time (equivalent to R's Sys.time())
   auto now = std::chrono::system_clock::now();
   auto time_t = std::chrono::system_clock::to_time_t(now);
   
   // Step 2: Format time as YYYYMMDDHHMMSS (equivalent to R's format(current_time, "%Y%m%d%H%M%S"))
   std::tm* tm_info = std::localtime(&time_t);
   std::ostringstream time_stream;
   time_stream << std::put_time(tm_info, "%Y%m%d%H%M%S");
   std::string time_string = time_stream.str();
   
   // Step 3: Generate random string (equivalent to R's sample(c(letters, LETTERS, 0:9), 50, replace=TRUE))
   // Character set: a-z (26), A-Z (26), 0-9 (10) = 62 characters total
   // Same as R's: c(letters, LETTERS, 0:9)
   const char chars[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
   std::string random_string;
   random_string.reserve(50);
   
   for (int i = 0; i < 50; ++i) {
     random_string += chars[dis_(gen_)];  // Sample with replacement (replace=TRUE)
   }
   
   // Step 4: Combine (equivalent to R's paste0(time_string, "-", random_string))
   return time_string + "-" + random_string;
 }
 
 } // namespace core
 } // namespace RCOMPSs
 
 