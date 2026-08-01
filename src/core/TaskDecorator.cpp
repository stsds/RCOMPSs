/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
 *
 * @file TaskDecorator.cpp
 * @brief Complete task decorator implementation
 * @version 1.0
 * @date 2025-01-XX
 */

#include <core/TaskDecorator.hpp>
#include <core/TypeChecker.hpp>
#include <core/TypeMapper.hpp>
#include <core/PathUtils.hpp>
#include <core/StringUtils.hpp>
#include <core/VectorUtils.hpp>
#include <core/UIDGenerator.hpp>
#include <Rcpp.h>

namespace RCOMPSs {
namespace core {

TaskExecutionResult TaskDecorator::executeTask(
    const std::string& function_name,
    Rcpp::List arguments,
    int arguments_length,
    const std::string& master_working_dir,
    const std::string& filename,
    const std::vector<std::string>& ser_method,
    bool return_value,
    const std::string& return_type) {
  
  TaskExecutionResult result;
  result.success = false;
  result.num_returns = 0;
  
  try {
    // Extract argument names
    Rcpp::CharacterVector arg_names_vec = arguments.names();
    std::vector<std::string> arguments_names;
    for (int i = 0; i < arguments_length; ++i) {
      if (i < arg_names_vec.size() && arg_names_vec[i] != R_NaString) {
        arguments_names.push_back(Rcpp::as<std::string>(arg_names_vec[i]));
      } else {
        arguments_names.push_back("");
      }
    }
    result.arguments_names = arguments_names;
    // Initialize vectors
    result.arguments_type = VectorUtils::repInteger(0, arguments_length);
    result.content_types = VectorUtils::repString("", arguments_length);
    
    // Process each argument
    for (int i = 0; i < arguments_length; ++i) {
      processSingleArgument(
        arguments,
        result.arguments_type,
        result.content_types,
        arguments_names,
        i,
        master_working_dir,
        ser_method[0],  // Input serialization method
        function_name
      );
    }
    // Process task metadata (directions, streams, prefixes, weights, keep_renames)
    TaskMetadata metadata = processTaskMetadata(arguments_length, return_value);
    result.compss_directions = metadata.compss_directions;
    result.compss_streams = metadata.compss_streams;
    result.compss_prefixes = metadata.compss_prefixes;
    result.weights = metadata.weights;
    result.keep_renames = metadata.keep_renames;
    result.num_returns = metadata.num_returns;
    
    // Handle return value if needed
    if (return_value) {
      buildReturnValue(result, master_working_dir, ser_method[1], arguments_length);
      
      // Add return value to arguments_type and content_types
      result.arguments_type.push_back(10);  // FILE type
      result.content_types.push_back("");
    }
    
    // Build registration info
    result.register_marker = StringUtils::buildRegisterMarker(function_name);
    // type_args_path will be built in R with getwd() since we can't call R functions from C++
    result.type_args_path = filename;  // Just the filename, R will prepend getwd()
    
    result.success = true;
    
  } catch (const Rcpp::exception& e) {
    result.error_message = std::string("TaskDecorator Rcpp error: ") + e.what();
    result.success = false;
  } catch (const std::exception& e) {
    result.error_message = std::string("TaskDecorator error: ") + e.what();
    result.success = false;
  } catch (...) {
    result.error_message = "TaskDecorator: Unknown error";
    result.success = false;
  }
  
  return result;
}

void TaskDecorator::processSingleArgument(
    Rcpp::List& arguments,
    std::vector<int>& arguments_type,
    std::vector<std::string>& content_types,
    const std::vector<std::string>& arguments_names,
    int index,
    const std::string& master_working_dir,
    const std::string& ser_method,
    const std::string& function_name) {
  
  try {
    // Get argument value
    SEXP arg = arguments[index];
    
    // Get R class and type
    Rcpp::Function class_r("class");
    Rcpp::Function typeof_r("typeof");
    Rcpp::Function length_r("length");
    
    Rcpp::CharacterVector class_vec = class_r(arg);
    int class_length = class_vec.size();  // length(class(arg))
    std::string r_class = (class_length > 0) ? Rcpp::as<std::string>(class_vec[0]) : "";
    std::string r_type = Rcpp::as<std::string>(typeof_r(arg));
    int arg_length = Rcpp::as<int>(length_r(arg));
    
    // Process argument - check length(class) == 1 as in original R code
    ProcessedArgument processed = processArgument(r_class, r_type, arg_length, class_length);
    
    arguments_type[index] = processed.compss_type;
    content_types[index] = processed.content_type;
    
  } catch (const Rcpp::exception& e) {
    // On error, default to FILE type
    arguments_type[index] = 10;
    content_types[index] = "object";
  } catch (const std::exception& e) {
    // On error, default to FILE type
    arguments_type[index] = 10;
    content_types[index] = "object";
  } catch (...) {
    // On error, default to FILE type
    arguments_type[index] = 10;
    content_types[index] = "object";
  }
}

ProcessedArgument TaskDecorator::processArgument(
    const std::string& r_class,
    const std::string& r_type,
    int length,
    int class_length) {
  
  ProcessedArgument result;
  
  // EXACTLY replicate R logic: length(class(arg)) == 1 && length(arg) == 1 && (class(arg) %in% c("integer", "numeric", "character"))
  if (class_length == 1 && length == 1 && (r_class == "integer" || r_class == "numeric" || r_class == "character")) {
    // Basic type - map to COMPSs type
    result.compss_type = TypeMapper::mapType(r_type);
    result.content_type = "";
    result.needs_serialization = false;
    result.is_future_object = false;
  } else {
    // Not basic type - needs serialization (FILE type = 10)
    result.compss_type = 10;  // FILE
    result.needs_serialization = true;
    
    // Check if it's a future_object - EXACTLY replicate R logic: length(class(obj)) == 1 && class(obj) == "future_object"
    if (class_length == 1 && r_class == "future_object") {
      result.is_future_object = true;
      result.content_type = "future_object";
    } else {
      result.is_future_object = false;
      result.content_type = "object";
    }
  }
  
  return result;
}

TaskMetadata TaskDecorator::processTaskMetadata(
    int arguments_length,
    bool has_return_value) {
  
  TaskMetadata metadata;
  
  // Initialize arguments_type with zeros
  metadata.arguments_type = VectorUtils::repInteger(0, arguments_length);
  
  // Initialize content_types with empty strings
  metadata.content_types = VectorUtils::repString("", arguments_length);
  
  if (has_return_value) {
    metadata.num_returns = 1;
    
    // Add return value to arguments_type (10L = FILE)
    metadata.arguments_type = VectorUtils::concatInteger(metadata.arguments_type, 10);
    
    // compss_directions: 0: in; 1: out (return value); 2: inout
    // All inputs are 0, return value is 1
    metadata.compss_directions = VectorUtils::repInteger(0, arguments_length);
    metadata.compss_directions = VectorUtils::concatInteger(metadata.compss_directions, 1);
    
    // compss_streams: (3,3,...,3) for all arguments + return
    metadata.compss_streams = VectorUtils::repInteger(3, arguments_length + 1);
    
    // compss_prefixes: "null" for all
    metadata.compss_prefixes = VectorUtils::repString("null", arguments_length + 1);
    
    // content_types: add empty string for return value
    metadata.content_types = VectorUtils::concatString(metadata.content_types, "");
    
    // weights: "1" for all
    metadata.weights = VectorUtils::repString("1", arguments_length + 1);
    
    // keep_renames: 0 for inputs, 1 for return value
    metadata.keep_renames = VectorUtils::repInteger(0, arguments_length);
    metadata.keep_renames = VectorUtils::concatInteger(metadata.keep_renames, 1);
  } else {
    metadata.num_returns = 0;
    
    // compss_directions: all 0 (inputs only)
    metadata.compss_directions = VectorUtils::repInteger(0, arguments_length);
    
    // compss_streams: all 3
    metadata.compss_streams = VectorUtils::repInteger(3, arguments_length);
    
    // compss_prefixes: all "null"
    metadata.compss_prefixes = VectorUtils::repString("null", arguments_length);
    
    // weights: all "1"
    metadata.weights = VectorUtils::repString("1", arguments_length);
    
    // keep_renames: all 0
    metadata.keep_renames = VectorUtils::repInteger(0, arguments_length);
  }
  
  return metadata;
}

void TaskDecorator::buildReturnValue(
    TaskExecutionResult& result,
    const std::string& master_working_dir,
    const std::string& ser_method,
    int arguments_length) {
  
  // Generate UID for return value
  std::string uid = UIDGenerator::generate();
  
  // Build return value filename - EXACTLY replicate R logic: paste0(MASTER_WORKING_DIR, "/", ser_method[2], "-", "ReturnValue_", UID())
  std::string result_path = master_working_dir;
  if (!result_path.empty() && result_path.back() != '/') {
    result_path += "/";
  }
  result.return_value_filename = result_path + ser_method + "-ReturnValue_" + uid;
  
  // Build return value name
  result.return_value_name = StringUtils::buildReturnValueName(ser_method);
  
  result.num_returns = 1;
}

Rcpp::Function TaskDecorator::createTaskDecorator(
    SEXP f,
    const std::string& filename,
    bool return_value,
    const std::string& return_type,
    Rcpp::CharacterVector ser_method,
    bool info_only,
    bool DEBUG,
    const std::string& f_name) {
  
  Rcpp::Function parse_func("parse");  // Needed later for parsing function body
  
  // Check MASTER_WORKING_DIR
  Rcpp::Function ls_func("ls");
  Rcpp::Function globalenv_func("globalenv");
  Rcpp::Environment global_env = globalenv_func();
  Rcpp::CharacterVector global_vars = ls_func(Rcpp::_["envir"] = global_env);
  bool has_master_dir = false;
  for (int i = 0; i < global_vars.size(); ++i) {
    if (Rcpp::as<std::string>(global_vars[i]) == "MASTER_WORKING_DIR") {
      has_master_dir = true;
      break;
    }
  }
  
  if (!has_master_dir) {
    Rcpp::Rcerr << "\033[0;31mHave you started COMPSs by calling `compss_start()`?\033[0m\n";
    Rcpp::stop("\033[0;31mMASTER_WORKING_DIR NOT FOUND!\033[0m");
  }
  // Verify f is actually a function
  Rcpp::Function is_function("is.function");
  bool f_is_function = Rcpp::as<bool>(is_function(f));
  if (!f_is_function) {
    Rcpp::stop("f must be a function");
  }
  
  // Delegate wrapper creation to R helper.
  try {

    Rcpp::Function getNamespace_func("getNamespace");
    Rcpp::Environment rcompss_ns = getNamespace_func("RCOMPSs");
    Rcpp::Function create_func = rcompss_ns["rcompss_create_task_decorator"];

    SEXP result = create_func(
      f,
      Rcpp::CharacterVector::create(f_name),
      filename,
      return_value,
      return_type,
      ser_method,
      info_only
    );

    // CRITICAL: Verify we got a function
    if (TYPEOF(result) != CLOSXP) {
      throw std::runtime_error("create_task_decorator did not return a function");
    }

    // Avoid deparse(formals/body) here to prevent evaluation side effects.
    
    return Rcpp::as<Rcpp::Function>(result);
  } catch (const std::exception& e) {
    throw;
  } catch (...) {
    throw;
  }
}

} // namespace core
} // namespace RCOMPSs

