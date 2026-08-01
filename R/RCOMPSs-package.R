## usethis namespace: start
#' @useDynLib RCOMPSs, .registration = TRUE
## usethis namespace: end
NULL

## usethis namespace: start
#' @importFrom Rcpp sourceCpp
## usethis namespace: end
NULL

# Rcpp-generated `rcompss_*` bindings (see R/RcppExports.R): export like TLAR's
# exportPattern so callers use RCOMPSs::rcompss_* instead of get(..., envir = ns).
#' @exportPattern ^rcompss_
NULL

#' Generate a unique ID
#' 
#' This function generates a unique identifier using a C++ implementation.
#' The UID format is: YYYYMMDDHHMMSS-randomstring
#' 
#' @return A unique string ID (format: YYYYMMDDHHMMSS-randomstring)
#' @export
UID <- function() {
  rcompss_generate_uid()
}

#' Start COMPSs runtime
#' 
#' Wrapper for start_runtime(). Also sets MASTER_WORKING_DIR in the global environment.
#' 
#' @export
compss_start <- function() {
  start_runtime()
  # Get master working directory from runtime and set it in global environment
  # Match original implementation exactly: Get_MasterWorkingDir() returns CharacterVector
  MASTER_WORKING_DIR <- Get_MasterWorkingDir()
  assign("MASTER_WORKING_DIR", MASTER_WORKING_DIR, envir = .GlobalEnv)
}

#' Stop COMPSs runtime
#' 
#' Wrapper for stop_runtime()
#' 
#' @param code Exit code
#' @export
compss_stop <- function(code = 0L) {
  stop_runtime(code)
}

#' COMPSs barrier
#' 
#' Wrapper for barrier()
#' 
#' @param app_id Application ID
#' @param no_more_tasks Whether there are no more tasks
#' @export
compss_barrier <- function(app_id = 0L, no_more_tasks = FALSE) {
  barrier(app_id, no_more_tasks)
}

#' Wait on future object
#' 
#' Wrapper for rcompss_wait_on()
#' 
#' @param future_obj Future object to wait on
#' @param mthreads Number of threads for serialization
#' @param nthreads Number of threads for parallel processing
#' @export
compss_wait_on <- function(future_obj, mthreads = 1L, nthreads = 1L) {
  rcompss_wait_on(future_obj, mthreads, nthreads)
}

#' Emit EXTRAE event
#'
#' @param group Integer defining the event group.
#' @param id Integer defining the event identifier.
#' @export
extrae_emit_event <- function(group, id) {
  .Call(`_RCOMPSs_Extrae_event_and_counters`, as.integer(group), as.integer(id))
}

#' Initialize EXTRAE
#'
#' @export
extrae_ini <- function() {
  .Call(`_RCOMPSs_Extrae_ini`)
}

#' Flush EXTRAE
#'
#' @export
extrae_flu <- function() {
  .Call(`_RCOMPSs_Extrae_flu`)
}

#' Finalize EXTRAE
#'
#' @export
extrae_fin <- function() {
  .Call(`_RCOMPSs_Extrae_fin`)
}

#' Serialize R object
#' 
#' Wrapper for rcompss_serialize()
#' 
#' @param object R object to serialize
#' @param filepath File path to save serialized object
#' @param ser_method Serialization method ("cpp" preferred; legacy "qs"/"RMVL" for reading old files)
#' @param mthreads Number of threads for serialization
#' @export
compss_serialize <- function(object, filepath, ser_method, mthreads = 1L) {
  rcompss_serialize(object, filepath, ser_method, mthreads)
}

#' Unserialize R object
#' 
#' Wrapper for rcompss_unserialize()
#' 
#' @param filepath File path to read serialized object from
#' @param mthreads Number of threads for unserialization
#' @export
compss_unserialize <- function(filepath, mthreads = 1L) {
  rcompss_unserialize(filepath, mthreads)
}

# Helper function to extract function name from function object
# Searches the function's environment and parent environments to find the name
.extract_function_name <- function(f, env = parent.frame()) {
  # First, try to get name from substitute() in the calling context
  # This works when the function is passed directly as a symbol
  tryCatch({
    f_name <- deparse(substitute(f, env = env))
    if (length(f_name) > 0 && f_name[1] != "f" && f_name[1] != "" && 
        f_name[1] != "structure" && !grepl("^\\(", f_name[1])) {
      return(f_name[1])
    }
  }, error = function(e) {})
  
  # If that fails, search environments for the function object
  # Start from the function's own environment, then parent frames, then global
  envs_to_search <- list(environment(f), env, globalenv())
  
  for (search_env in envs_to_search) {
    if (is.null(search_env)) next
    
    tryCatch({
      # Get all objects in this environment
      obj_names <- ls(envir = search_env, all.names = TRUE)
      
      for (name in obj_names) {
        tryCatch({
          obj <- get(name, envir = search_env, inherits = FALSE)
          # Check if this object is the same function (using identical)
          if (identical(obj, f, ignore.environment = FALSE)) {
            return(name)
          }
        }, error = function(e) {})
      }
    }, error = function(e) {})
  }
  
  # Last resort: try to get from function body/environment attributes
  f_env <- environment(f)
  if (!is.null(f_env)) {
    tryCatch({
      # Sometimes functions have their name in the environment
      if (exists(".function_name", envir = f_env)) {
        name <- get(".function_name", envir = f_env)
        if (is.character(name) && length(name) > 0) {
          return(name[1])
        }
      }
    }, error = function(e) {})
  }
  
  return(NULL)
}

# Constraint decorator
# Must be placed ON TOP of the @task decorator (applied first, then task)
# 
# Supported constraints (all accept string values unless noted):
#   - computing_units: Required number of computing units (default: "1")
#   - is_local: Task must execute in the node where detected (TRUE/FALSE, default: FALSE)
#   - processor_name, processor_speed, processor_architecture, processor_type,
#     processor_property_name, processor_property_value, processor_internal_memory_size
#   - processors: List of Processor objects (see below)
#   - memory_size, memory_type: Memory requirements
#   - storage_size, storage_type: Storage requirements
#   - operating_system_type, operating_system_distribution, operating_system_version
#   - wall_clock_limit: Maximum wall clock time
#   - host_queues: Required queues (comma-separated for multiple values)
#   - app_software: Required applications (comma-separated for multiple values)
# 
# Processor structure (for processors constraint):
#   Each processor is a list with fields:
#     - processorType: "CPU" or "GPU" (default: "CPU")
#     - computingUnits: Number of units (default: "1")
#     - name, speed, architecture, propertyName, propertyValue, internalMemorySize
# 
# Usage examples:
#   constraint(f, computing_units = "4")
#   constraint(f, computing_units = "4", app_software = "numpy,scipy,gnuplot", memory_size = "$MIN_MEM_REQ")
#   constraint(f, processors = list(
#     list(processorType = "CPU", computingUnits = "1"),
#     list(processorType = "GPU", computingUnits = "1", name = "Tesla V100")
#   ))
#   constraint(f, is_local = TRUE)
# 
# The constraints are stored as attributes and passed to register_core_element via ImplConstraints
# Format: key:value;key2:value2;
#' @export
constraint <- function(f, ...) {
  # Get constraint arguments from ...
  constraint_args <- list(...)
  
  # Remove NULL values
  constraint_args <- constraint_args[!sapply(constraint_args, is.null)]
  
  if (length(constraint_args) == 0) {
    warning("No constraints provided to constraint decorator")
    return(f)
  }
  
  # Convert all values to strings for consistency (handles numeric, character, logical, etc.)
  # COMPSs expects lowercase "true"/"false" for booleans, not "True"/"False"
  constraint_args_str <- lapply(constraint_args, function(x) {
    if (is.character(x) && length(x) == 1) {
      return(x)  # Already a string
    } else if (is.numeric(x) && length(x) == 1) {
      return(as.character(x))  # Convert number to string
    } else if (is.logical(x) && length(x) == 1) {
      return(ifelse(x, "true", "false"))  # Convert boolean to lowercase (COMPSs format)
    } else if (is.list(x)) {
      return(x)  # Keep lists as-is (for processors)
    } else {
      return(as.character(x))  # Fallback: convert to string
    }
  })
  
  # Convert constraint names from snake_case to camelCase for COMPSs compatibility
  # e.g., is_local -> isLocal, computing_units -> computingUnits
  names(constraint_args_str) <- sapply(names(constraint_args_str), function(name) {
    # Split on underscore and convert to camelCase
    parts <- strsplit(name, "_")[[1]]
    if (length(parts) == 1) {
      return(name)  # No underscore, return as-is
    }
    # First part lowercase, rest capitalized
    result <- parts[1]
    for (i in 2:length(parts)) {
      result <- paste0(result, toupper(substring(parts[i], 1, 1)), substring(parts[i], 2))
    }
    return(result)
  })
  
  # Extract and store the original function name FIRST (before adding constraints)
  # CRITICAL: Use substitute() here because we're being called with the original function
  # e.g., constraint(add, ...) - so substitute(f) will give us "add"
  # This is the ONLY reliable way to get the name when constraint() is first called
  f_name <- deparse(substitute(f))
  
  # Validate the extracted name - must be a simple identifier, not decorated
  if (length(f_name) > 0 && f_name[1] != "f" && f_name[1] != "" && 
      f_name[1] != "structure" && !grepl("^\\(", f_name[1]) &&
      !grepl("_constrained$", f_name[1])) {  # Don't store decorated names
    # Store BOTH attributes at once using structure() to ensure both are preserved
    f <- structure(f, 
                   RCOMPSs_constraints = constraint_args_str,
                   RCOMPSs_original_function_name = f_name[1])
  } else {
    # If we couldn't extract the name, just store constraints
    attr(f, "RCOMPSs_constraints") <- constraint_args_str
  }
  
  return(f)
}

# Override the task function from RcppExports.R to extract f_name using match.call()
# This MUST be defined after RcppExports.R is loaded to override it
# Since R files load alphabetically, RCOMPSs-package.R loads after RcppExports.R
# Define the wrapper function (not exported - internal use only)
task_wrapper_impl <- function(f, filename, return_value = FALSE, return_type = "list", ser_method = NULL, info_only = FALSE, DEBUG = FALSE) {
  # Check environment variable for default serialization method if not provided
  if (is.null(ser_method)) {
    env_method <- Sys.getenv("RCOMPSs_SERIALIZATION", unset = "")
    if (env_method != "") {
      # Normalize to lowercase for comparison
      env_method_lower <- tolower(env_method)
      if (env_method_lower %in% c("cpp", "qs", "rmvl")) {
        ser_method <- as.character(c(env_method, env_method))
      } else {
        warning("Invalid RCOMPSs_SERIALIZATION value '", env_method, "'. Valid values: cpp, qs, RMVL. Using default 'cpp'.")
        ser_method <- as.character(c("cpp", "cpp"))
      }
    } else {
      # Default to cpp if environment variable is not set
      ser_method <- as.character(c("cpp", "cpp"))
    }
  }
  
  # Extract function name - ALWAYS check stored name first
  # The constraint decorator stores the original function name when called
  # e.g., constraint(add, ...) stores "add", so task() should use that
  original_f_name <- attr(f, "RCOMPSs_original_function_name", exact = TRUE)
  
  if (!is.null(original_f_name) && length(original_f_name) > 0 && 
      !is.na(original_f_name) && original_f_name != "" && 
      original_f_name != "f" && original_f_name != "structure" &&
      !grepl("_constrained$", original_f_name)) {  # Avoid decorated names
    f_name <- as.character(original_f_name)[1]
  } else {
    # No stored name - try to extract from function object
    # But be careful: if function was decorated, we might get the wrong name
    # So prefer searching the function's original environment
    f_env <- environment(f)
    f_name <- NULL
    
    # Try to find the function in its original environment (before decoration)
    if (!is.null(f_env)) {
      tryCatch({
        obj_names <- ls(envir = f_env, all.names = TRUE)
        for (name in obj_names) {
          tryCatch({
            obj <- get(name, envir = f_env, inherits = FALSE)
            # Use identical with ignore.environment = TRUE to match the function body
            # even if it has been wrapped with attributes
            if (is.function(obj) && identical(body(obj), body(f), ignore.environment = FALSE)) {
              # Check if this is likely the original (not a decorated version)
              if (!grepl("_constrained$", name)) {
                f_name <- name
                break
              }
            }
          }, error = function(e) {})
        }
      }, error = function(e) {})
    }
    
    # Fallback to substitute() if environment search failed
    if (is.null(f_name) || f_name == "" || f_name == "f" || f_name == "structure") {
      f_name <- deparse(substitute(f))
      if (length(f_name) > 1) {
        f_name <- f_name[1]
      }
      
      # Final fallback to match.call()
      if (length(f_name) == 0 || f_name == "" || is.na(f_name) || f_name == "f" || f_name == "structure") {
        mc <- match.call()
        mc_list <- as.list(mc)
        if (!is.null(mc_list$f)) {
          f_name <- as.character(mc_list$f)
          if (length(f_name) > 1) {
            f_name <- f_name[1]
          }
        }
      }
    }
    
    # Final validation
    if (is.null(f_name) || length(f_name) == 0 || f_name == "" || is.na(f_name) || f_name == "f" || f_name == "structure") {
      stop("Could not extract function name. Please pass the function as a symbol, e.g., task(add, ...) instead of task(function(...), ...)")
    }
  }
  
  # Call the Rcpp-exported function, passing the function name
  # Use .Call() directly to pass all parameters including f_name
  .Call(`_RCOMPSs_task`, f, filename, return_value, return_type, ser_method, info_only, DEBUG, f_name)
}

#' Task decorator
#' 
#' Main task decorator function. The actual implementation is in C++ TaskDecorator class.
#' 
#' @param f The function to be executed
#' @param filename Character. The file where the function is defined
#' @param return_value Boolean. Default value is FALSE. Whether there is a return value
#' @param return_type Character. Default value is "list". Return type ("list" or "element")
#' @param ser_method Character vector. Default value is c("cpp", "cpp"). Serialization method
#' @param info_only Boolean. Whether the run is to print the information only
#' @param DEBUG Boolean. Whether to print debug information
#' @export
# Assign task to our wrapper - this should override RcppExports.R version
# since this file loads after RcppExports.R alphabetically
# This is the exported function that users call
task <- task_wrapper_impl

# Override process_task from RcppExports.R to ensure proper character conversion
# This fixes the "Expecting a single string value: [type=symbol; extent=1]" error
process_task <- function(app_id, signature, on_failure, time_out, priority, num_nodes, reduce, chunk_size, replicated, distributed, has_target, num_returns, values, names, compss_types, compss_directions, compss_streams, compss_prefixes, content_types, weights, keep_renames) {
  # DEBUG: Verify override is being called
  flush.console()
  
  # CRITICAL: Force evaluation IMMEDIATELY to break any symbol references
  # Evaluate signature and on_failure in the calling environment to resolve any promises
  sig_eval <- eval(substitute(signature), envir = parent.frame())
  on_fail_eval <- eval(substitute(on_failure), envir = parent.frame())
  
  # Force evaluation
  force(sig_eval)
  force(on_fail_eval)
  
  # CRITICAL: Convert to character using paste0 to create completely new strings
  # This breaks any symbol references
  sig_str <- paste0(as.character(sig_eval)[1], "")
  on_fail_str <- paste0(as.character(on_fail_eval)[1], "")
  
  # Force evaluation again
  force(sig_str)
  force(on_fail_str)
  
  
  # Verify they are character vectors of length 1
  if (!is.character(sig_str) || length(sig_str) != 1) {
    stop(paste("process_task override: sig_str is not character(1):", typeof(sig_str), length(sig_str)))
  }
  if (!is.character(on_fail_str) || length(on_fail_str) != 1) {
    stop(paste("process_task override: on_fail_str is not character(1):", typeof(on_fail_str), length(on_fail_str)))
  }
  
  # Call the C function directly with converted values as CharacterVector
  # Convert to CharacterVector to match C++ function signature
  sig_cv <- c(sig_str)
  on_fail_cv <- c(on_fail_str)
  # Use invisible() to suppress return value
  invisible(.Call(`_RCOMPSs_process_task`, 
    as.integer(app_id), 
    sig_cv, 
    on_fail_cv, 
    as.integer(time_out), 
    as.integer(priority), 
    as.integer(num_nodes), 
    as.integer(reduce), 
    as.integer(chunk_size), 
    as.integer(replicated), 
    as.integer(distributed), 
    as.integer(has_target), 
    as.integer(num_returns), 
    values, 
    names, 
    compss_types, 
    compss_directions, 
    compss_streams, 
    compss_prefixes, 
    content_types, 
    weights, 
    keep_renames))
}

# Helper function to call process_task C++ function with guaranteed character conversion
# This function ensures signature and on_failure are properly converted to character
# before being passed to Rcpp, avoiding the "Expecting a single string value" error
rcompss_call_process_task <- function(app_id, signature, on_failure, time_out, priority, 
                                     num_nodes, reduce, chunk_size, replicated, distributed, 
                                     has_target, num_returns, values, names, compss_types, 
                                     compss_directions, compss_streams, compss_prefixes, 
                                     content_types, weights, keep_renames) {
  # CRITICAL: Force complete evaluation to break any symbol references
  # Use multiple evaluation steps to ensure we get actual character values
  sig_eval <- eval(substitute(signature), envir = parent.frame())
  on_fail_eval <- eval(substitute(on_failure), envir = parent.frame())
  
  # Force evaluation multiple times
  force(sig_eval)
  force(on_fail_eval)
  
  # Convert to character and create completely new strings using sprintf
  # This ensures no symbol references remain
  sig_str <- sprintf("%s", as.character(sig_eval)[1])
  on_fail_str <- sprintf("%s", as.character(on_fail_eval)[1])
  
  # Force evaluation
  force(sig_str)
  force(on_fail_str)
  
  # Create CharacterVector using c() with the string - this creates a new object
  sig_cv <- c(sig_str)
  on_fail_cv <- c(on_fail_str)
  
  # Ensure they're length 1 CharacterVectors (not scalars)
  if (length(sig_cv) == 0 || is.na(sig_cv[1])) {
    sig_cv <- c("")
  }
  if (length(on_fail_cv) == 0 || is.na(on_fail_cv[1])) {
    on_fail_cv <- c("RETRY")
  }
  
  # Force final evaluation
  force(sig_cv)
  force(on_fail_cv)
  
  # CRITICAL: Verify they are character vectors, not symbols
  if (!is.character(sig_cv)) {
    stop(paste("rcompss_call_process_task: sig_cv is not character, type:", typeof(sig_cv)))
  }
  if (!is.character(on_fail_cv)) {
    stop(paste("rcompss_call_process_task: on_fail_cv is not character, type:", typeof(on_fail_cv)))
  }
  
  # Build argument list with all values pre-evaluated
  call_args <- list(
    `_RCOMPSs_process_task`,
    as.integer(app_id),
    sig_cv,
    on_fail_cv, 
    as.integer(time_out), 
    as.integer(priority), 
    as.integer(num_nodes), 
    as.integer(reduce), 
    as.integer(chunk_size), 
    as.integer(replicated), 
    as.integer(distributed), 
    as.integer(has_target), 
    as.integer(num_returns), 
    values, 
    names, 
    compss_types, 
    compss_directions, 
    compss_streams, 
    compss_prefixes, 
    content_types, 
    weights, 
    keep_renames
  )
  
  # Force evaluation of entire list
  force(call_args)

  # Use do.call() to ensure all arguments are fully evaluated
  invisible(do.call(.Call, call_args))
}

# Helper to create the decorated task function in R
rcompss_create_task_decorator <- function(f, f_name, filename, return_value, return_type,
                                         ser_method, info_only) {
  force(f)

  # Capture values in a dedicated environment to avoid lookup issues.
  env <- new.env(parent = globalenv())
  env$f <- f
  env$f_name <- f_name
  env$filename <- filename
  env$return_value <- return_value
  env$return_type <- return_type
  env$ser_method <- ser_method
  env$info_only <- info_only

  fun <- function(...) {
    do.call(
      getNamespace("RCOMPSs")$rcompss_execute_decorated_task,
      c(
        list(
          f = f,
          f_name = f_name,
          filename = filename,
          return_value = return_value,
          return_type = return_type,
          ser_method = ser_method,
          info_only = info_only
        ),
        list(...)
      )
    )
  }

  environment(fun) <- env
  fun
}

# Internal helper function for task decorator execution
# This function handles the R-specific argument matching and calls the C++ functions
# This replaces the 400+ lines of R code that were being generated as strings in C++
rcompss_execute_decorated_task <- function(f, f_name, filename, return_value, return_type, 
                                           ser_method, info_only, ...) {
  # Get function formals (parameter definitions)
  arguments <- formals(f)
  # function() {} gives NULL formals in R; normalize so length-0 logic is safe.
  if (is.null(arguments)) {
    arguments <- pairlist()
  }
  
  # Handle different argument patterns
  # formals(function(...) x) gives names c("..."), not the string "..." — accept COMPSs-only tasks.
  arg_formal_names <- names(arguments)
  if (length(arguments) == 1L && identical(arg_formal_names, c("..."))) {
    # Only `...`: master call supplies real args via ...; worker may pass extra named slots.
    arguments <- list(...)
    arg_names <- rcompss_build_variable_argument_names(f_name, length(arguments))
    names(arguments) <- arg_names
  } else if (length(arguments) > 1L && !is.null(arg_formal_names) && "..." %in% arg_formal_names) {
    stop("Variable argument `...` with other inputs is not supported yet!")
  } else {
    # Function has named parameters
    values <- list(...)
    arguments.names <- names(arguments)
    
    if (is.null(names(values))) {
      # Positional arguments — use seq_along: 1:length() is c(1,0) when length is 0 (pre-R-4.0)
      for (arg_ind in seq_along(arguments)) {
        if (arg_ind <= length(values)) {
          arguments[[arg_ind]] <- values[[arg_ind]]
        }
      }
    } else {
      # Named arguments - match by name
      unnamed.values.ind <- which(names(values) == "")
      k <- 1
      for (arg_ind in seq_along(arguments)) {
        if (arguments.names[arg_ind] %in% names(values)) {
          arguments[[arg_ind]] <- values[[arguments.names[arg_ind]]]
        } else if (length(unnamed.values.ind) > 0 && k <= length(unnamed.values.ind)) {
          arguments[[arg_ind]] <- values[[unnamed.values.ind[k]]]
          k <- k + 1
        }
      }
    }
  }
  
  # Convert pairlist to list if needed
  if (is.pairlist(arguments)) {
    arg_names <- names(arguments)
    arguments <- as.list(arguments)
    if (is.null(names(arguments)) && !is.null(arg_names)) {
      names(arguments) <- arg_names
    }
  }
  
  arguments_length <- length(arguments)
  
  # Ensure arguments has names
  if (is.null(names(arguments))) {
    if (arguments_length > 0) {
      names(arguments) <- rep("", arguments_length)
    } else {
      names(arguments) <- character(0)
    }
  }
  
  # Get MASTER_WORKING_DIR
  MASTER_WORKING_DIR <- get("MASTER_WORKING_DIR", envir = globalenv())
  
  # Call C++ function to process the task
  task_result <- rcompss_execute_task(
    function_name = f_name,
    arguments = arguments,
    arguments_length = arguments_length,
    master_working_dir = MASTER_WORKING_DIR,
    filename = filename,
    ser_method = ser_method,
    return_value = return_value,
    return_type = return_type
  )
  
  if (!task_result$success) {
    stop(paste("C++ TaskDecorator failed:", task_result$error_message))
  }
  
  # Register and call process_task if not info_only
  if (!info_only) {
    type_args_path <- paste0(getwd(), '/', task_result$type_args_path)
    
    # Check for constraints stored on the function FIRST to build unique marker
      constraints_attr <- attr(f, "RCOMPSs_constraints")
    
    # Build a unique marker that includes constraint signature
    # This allows the same function to be registered with different constraints
    constraint_sig <- ""
    if (!is.null(constraints_attr) && length(constraints_attr) > 0) {
      # Create a signature from constraint names and simplified values
      constraint_sig <- paste(names(constraints_attr), collapse = ",")
      # For processors list, include a simplified representation
      for (key in names(constraints_attr)) {
        val <- constraints_attr[[key]]
        if (is.list(val)) {
          # For processors list, create a signature that includes all fields
          proc_sig <- sapply(val, function(p) {
            if (is.list(p)) {
              # Include all fields in a consistent order: processorType, computingUnits, name, etc.
              field_order <- c("processorType", "computingUnits", "name", "speed", "architecture", 
                              "propertyName", "propertyValue", "internalMemorySize")
              sig_parts <- character(0)
              for (field in field_order) {
                if (field %in% names(p)) {
                  sig_parts <- c(sig_parts, paste0(field, "=", as.character(p[[field]])))
                }
              }
              # Add any remaining fields not in the standard order
              for (field in names(p)) {
                if (!field %in% field_order) {
                  sig_parts <- c(sig_parts, paste0(field, "=", as.character(p[[field]])))
                }
              }
              paste(sig_parts, collapse = ",")
            } else {
              as.character(p)
            }
          })
          constraint_sig <- paste0(constraint_sig, ":", paste(proc_sig, collapse = ";"))
        } else {
          constraint_sig <- paste0(constraint_sig, ":", as.character(val))
        }
      }
      # Create a simple hash-like string (first 16 chars of the signature, sanitized)
      constraint_sig <- gsub("[^A-Za-z0-9]", "_", constraint_sig)
      constraint_sig <- substr(constraint_sig, 1, 32)  # Limit length
    }
    register_marker <- paste0("registered_", f_name, ifelse(constraint_sig != "", paste0("_", constraint_sig), ""))
    
    if (!exists(register_marker, envir = globalenv())) {
      constraint_string <- ""
      impl_local <- "False"  # Default value
      
      if (!is.null(constraints_attr) && length(constraints_attr) > 0) {
        
        # Handle is_local separately - it goes to ImplLocal parameter, not ImplConstraints
        # Note: constraint names are converted to camelCase in constraint(), so check for "isLocal"
        is_local_key <- NULL
        if ("isLocal" %in% names(constraints_attr)) {
          is_local_key <- "isLocal"
        } else if ("is_local" %in% names(constraints_attr)) {
          # Fallback: check for snake_case (shouldn't happen after camelCase conversion, but be safe)
          is_local_key <- "is_local"
        }
        
        if (!is.null(is_local_key)) {
          is_local_val <- constraints_attr[[is_local_key]]
          # Convert to COMPSs format: "True" or "False" (capitalized, as per ImplLocal convention)
          if (is.character(is_local_val)) {
            if (tolower(is_local_val) == "true") {
              impl_local <- "True"
            } else {
              impl_local <- "False"
            }
          } else if (is.logical(is_local_val) && is_local_val) {
            impl_local <- "True"
          } else {
            impl_local <- "False"
          }
          # Remove isLocal/is_local from constraints before building constraint string
          constraints_attr <- constraints_attr[names(constraints_attr) != is_local_key]
        }
        
        # Build constraint string from remaining constraints (excluding is_local)
        if (length(constraints_attr) > 0) {
          constraint_string <- rcompss_build_constraint_string(constraints_attr)
        } else {
        }
      }
      register_core_element(
        CESignature = f_name,
        ImplSignature = f_name,
        ImplConstraints = constraint_string,
        ImplType = "METHOD",
        ImplLocal = impl_local,
        ImplIO = "False",
        prolog = c("", "", "False"),
        epilog = c("", "", "False"),
        container = c("", "", ""),
        typeArgs = c("R", type_args_path, f_name)
      )
      assign(register_marker, TRUE, envir = globalenv())
    }
    
    # Clean processed_arguments - remove any symbols
    proc_args_clean <- list()
    proc_names_clean <- character(0)
    for (i in seq_along(task_result$processed_arguments)) {
      if (!is.symbol(task_result$processed_arguments[[i]])) {
        proc_args_clean[[length(proc_args_clean) + 1]] <- task_result$processed_arguments[[i]]
        if (!is.null(names(task_result$processed_arguments))) {
          proc_names_clean[length(proc_names_clean) + 1] <- names(task_result$processed_arguments)[i]
        }
      }
    }
    if (length(proc_names_clean) > 0) {
      names(proc_args_clean) <- proc_names_clean
    }
    
    # Call process_task
    process_task(
      app_id = 0L,
      signature = f_name,
      on_failure = "RETRY",
      time_out = 0L,
      priority = 0L,
      num_nodes = 1L,
      reduce = 0L,
      chunk_size = 0L,
      replicated = 0L,
      distributed = 0L,
      has_target = 0L,
      num_returns = task_result$num_returns,
      values = proc_args_clean,
      names = as.character(task_result$arguments_names),
      compss_types = task_result$arguments_type,
      compss_directions = task_result$compss_directions,
      compss_streams = task_result$compss_streams,
      compss_prefixes = as.character(task_result$compss_prefixes),
      content_types = as.character(task_result$content_types),
      weights = as.character(task_result$weights),
      keep_renames = task_result$keep_renames
    )
    
    # Return future object if return_value is TRUE
    if (return_value) {
      outputfile <- task_result$return_value_filename
      if (return_type == "element") {
        FO <- outputfile
        class(FO) <- "future_object_path"
      } else if (return_type == "list") {
        FO <- list("outputfile" = outputfile)
        class(FO) <- "future_object"
      }
      return(FO)
    }
  }
  
  return(invisible(NULL))
}

# Also ensure it's set in .onLoad (runs after all files are loaded)
.onLoad <- function(libname, pkgname) {
  ns <- asNamespace(pkgname)
  # Get task_wrapper_impl from the namespace (it should be there since all R files are loaded)
  if (exists("task_wrapper_impl", envir = ns, inherits = FALSE)) {
    wrapper <- get("task_wrapper_impl", envir = ns)
    # Unlock if locked
    if (bindingIsLocked("task", ns)) {
      unlockBinding("task", ns)
    }
    # Reassign to ensure our version is used
    assign("task", wrapper, envir = ns)
    # Lock it back
    lockBinding("task", ns)
  }
  # Override process_task to ensure proper character conversion
  # The process_task function defined above should override the one from RcppExports.R
  # Since RCOMPSs-package.R loads after RcppExports.R alphabetically, our definition takes precedence
  # But we'll explicitly ensure it's set in .onLoad to be safe
  if (bindingIsLocked("process_task", ns)) {
    unlockBinding("process_task", ns)
  }
  # Explicitly assign our override function to ensure it's used
  # Get the function from the current environment (this file)
  process_task_override <- process_task
  assign("process_task", process_task_override, envir = ns)
}
