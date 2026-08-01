/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file TaskDecorator.hpp
 * @brief Complete task decorator logic - replaces entire task() function
 * @version 1.0
 * @date 2025-01-XX
 */

#ifndef RCOMPSs_TASKDECORATOR_HPP
#define RCOMPSs_TASKDECORATOR_HPP

#include <string>
#include <vector>
#include <Rcpp.h>

namespace RCOMPSs {
namespace core {

/**
 * @struct ProcessedArgument
 * @brief Information about a processed argument
 */
struct ProcessedArgument {
  int compss_type;              // COMPSs type number (0-10)
  std::string content_type;     // Content type string ("object", "future_object", etc.)
  bool needs_serialization;     // Whether argument needs serialization
  bool is_future_object;        // Whether argument is a future_object
};

/**
 * @struct TaskMetadata
 * @brief Metadata structure for processed task arguments
 */
struct TaskMetadata {
  std::vector<int> arguments_type;        // COMPSs type numbers
  std::vector<int> compss_directions;     // 0: in; 1: out; 2: inout
  std::vector<int> compss_streams;        // Stream numbers (usually 3)
  std::vector<std::string> compss_prefixes; // Prefixes (usually "null")
  std::vector<std::string> content_types;   // Content type strings
  std::vector<std::string> weights;         // Weight strings (usually "1")
  std::vector<int> keep_renames;            // Keep rename flags (0 or 1)
  int num_returns;                          // Number of return values (0 or 1)
};

/**
 * @struct TaskExecutionResult
 * @brief Complete result from task execution processing
 */
struct TaskExecutionResult {
  // Processed arguments (after serialization if needed)
  Rcpp::List processed_arguments;
  std::vector<std::string> arguments_names;
  std::vector<int> arguments_type;
  std::vector<std::string> content_types;
  
  // COMPSs metadata vectors
  std::vector<int> compss_directions;
  std::vector<int> compss_streams;
  std::vector<std::string> compss_prefixes;
  std::vector<std::string> weights;
  std::vector<int> keep_renames;
  
  // Return value info
  int num_returns;
  std::string return_value_filename;  // If has return value
  std::string return_value_name;
  
  // Registration info
  std::string register_marker;
  std::string type_args_path;
  
  // Success flag
  bool success;
  std::string error_message;
};

/**
 * @class TaskDecorator
 * @brief Complete task decorator implementation - handles all task processing
 * 
 * This class replaces the entire logic inside the task() decorator function.
 * It consolidates:
 * - Argument processing and type determination
 * - Task metadata generation
 * - Return value preparation
 * - Registration info building
 * 
 * All task-related processing is handled in this single class.
 */
class TaskDecorator {
public:
  /**
   * @brief Execute complete task processing
   * 
   * This is the main entry point that processes everything:
   * 1. Processes and matches arguments
   * 2. Determines types for each argument
   * 3. Handles serialization preparation for non-basic types
   * 4. Builds all COMPSs metadata vectors
   * 5. Prepares return value if needed
   * 6. Prepares registration info
   * 
   * @param function_name Name of the function being decorated
   * @param arguments R list of arguments (from formals or ...)
   * @param arguments_length Number of arguments
   * @param master_working_dir Master working directory path
   * @param filename Filename where function is defined
   * @param ser_method Serialization method (vector of 2 strings: [input, output])
   * @param return_value Whether function has return value
   * @param return_type Return type ("list" or "element")
   * @return TaskExecutionResult with all processed data
   */
  static TaskExecutionResult executeTask(
    const std::string& function_name,
    Rcpp::List arguments,
    int arguments_length,
    const std::string& master_working_dir,
    const std::string& filename,
    const std::vector<std::string>& ser_method,
    bool return_value,
    const std::string& return_type
  );
  
  /**
   * @brief Process task metadata (directions, streams, prefixes, weights, keep_renames)
   * 
   * This is a public method so it can be called from rcompss_process_task_metadata
   */
  static TaskMetadata processTaskMetadata(
    int arguments_length,
    bool has_return_value
  );
  
  /**
   * @brief Create task decorator - returns R function closure
   * 
   * This is the main entry point that creates the task decorator.
   * It creates an R function closure that handles the entire decorator pattern.
   * All logic is in C++ - this replaces task.R entirely.
   * 
   * @param f The function to be executed (R function)
   * @param filename Character. The file where the function is defined
   * @param return_value Boolean. Whether there is a return value
   * @param return_type Character. Return type ("list" or "element")
   * @param ser_method Character vector. Serialization method
   * @param info_only Boolean. Whether the run is to print the information only
   * @param DEBUG Boolean. Whether to print debug information
   * @return The decorated function (R function closure)
   */
  static Rcpp::Function createTaskDecorator(
    SEXP f,
    const std::string& filename,
    bool return_value,
    const std::string& return_type,
    Rcpp::CharacterVector ser_method,
    bool info_only,
    bool DEBUG,
    const std::string& f_name = ""
  );
  
private:
  /**
   * @brief Process a single argument (type determination, serialization)
   */
  static void processSingleArgument(
    Rcpp::List& arguments,
    std::vector<int>& arguments_type,
    std::vector<std::string>& content_types,
    const std::vector<std::string>& arguments_names,
    int index,
    const std::string& master_working_dir,
    const std::string& ser_method,
    const std::string& function_name
  );
  
      /**
       * @brief Process argument and determine its type
       * 
       * Replicates exact R logic: length(class(arg)) == 1 && length(arg) == 1 && (class(arg) %in% c("integer", "numeric", "character"))
       */
      static ProcessedArgument processArgument(
        const std::string& r_class,
        const std::string& r_type,
        int length,
        int class_length
      );
  
  /**
   * @brief Build return value filename and metadata
   */
  static void buildReturnValue(
    TaskExecutionResult& result,
    const std::string& master_working_dir,
    const std::string& ser_method,
    int arguments_length
  );
};

} // namespace core
} // namespace RCOMPSs

#endif // RCOMPSs_TASKDECORATOR_HPP

