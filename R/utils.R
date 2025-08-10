
# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

# @file utils.R
# @brief This file contains the main function for the RCOMPSs package
# @version 1.0
# @author Xiran Zhang
# @date 2025-04-28

accessed_objects_map <- new.env()

check_key_in_hashmap <- function(key, env) {
  exists(key, envir = env, inherits = FALSE)
}

#' task
#'
#' This function is the decorator for tasks.
#'
#' @param f The function to be executed.
#' @param filename Character. The file where the function is defined.
#' @param return_value Boolean. Default value is FALSE. Whether there is a return value.
#' @param f_dir Absolute directory of the file where f is defined.
#' @param info_only Boolean. Whether the run is to print the information only.
#' @param ... Metadata.
#' @return The decorated function
#' @export
task <- function(f, filename, return_value = FALSE, info_only = FALSE, DEBUG = FALSE, ser_method = "RMVL", ...) {
  TIME1 <- proc.time()

  # Convert all the metadata into a list
  metadata <- list(...)

  # Obtain the name of the function we are decorating
  f_name <- as.character(as.list(match.call())$f)

  # If we have NOT already got <MASTER_WORKING_DIR>, assign <MASTER_WORKING_DIR> to current working directory
  if (!("MASTER_WORKING_DIR" %in% ls(envir = globalenv()))) {
    # MASTER_WORKING_DIR <- getwd()
    cat("\033[0;31mHave you started COMPSs by calling `compss_start()`?\033[0m\n")
    stop("\033[0;31mMASTER_WORKING_DIR NOT FOUND!\033[0m")
  }

  # This function will be returned as the decorated version of <f>
  function(...) {
    # The application id is always 0L
    app_id <- 0L

    #################################################
    # Process the arguments
    #################################################

    ## The argument list of f with the names of the parameters and the default values
    ## TODO: Support ... input in f
    arguments <- formals(f)
    if (DEBUG) {
      cat("arg list:\n")
      print(arguments)
    }
    if (identical(names(arguments), "...")) {
      if (DEBUG) {
        cat("The decorated function only has variable `...` inputs\n")
      }
      arguments <- list(...)
      names(arguments) <- paste0(paste0(f_name, "___"), 1:length(arguments))
    } else if ("..." %in% names(arguments)) {
      print(list(...))
      stop("Variable argument `...` with other inputs is not supported yet!")
    } else {
      ## Obtain the received values:
      values <- list(...)
      if (DEBUG) {
        cat("Received:\n")
        cat("-----------------------------------------------------------------\n")
        print(values)
        cat("\n-----------------------------------------------------------------\n")
        print(values[[1]])
        cat("\n-----------------------------------------------------------------\n")
        cat("names(values):\n")
        print(names(values))
      }

      ## Assign the values to the correct arguments
      arguments.names <- names(arguments)
      if (is.null(names(values))) {
        for (arg_ind in 1:length(arguments)) {
          arguments[[arg_ind]] <- values[[arg_ind]]
        }
      } else {
        unnamed.values.ind <- which(names(values) == "")
        k <- 1
        for (arg_ind in 1:length(arguments)) {
          if (arguments.names[arg_ind] %in% names(values)) {
            arguments[[arg_ind]] <- values[[arg_ind]]
          } else {
            arguments[[arg_ind]] <- values[[unnamed.values.ind[k]]]
            k <- k + 1
          }
        }
      }
    }

    if (DEBUG) {
      cat("Processed arguments:\n")
      print(arguments)
    }

    # The parent environment
    # pf <- parent.frame()
    # cat("The parent frame:\n")
    # print(pf)
    # cat("args_names:\n")
    # my.names <- ls(envir = pf, all.names = TRUE, sorted = FALSE);
    # print(my.names)
    # if("..." %in% my.names) {
    #   dots <- eval(quote(list(...)), envir = pf)
    # }  else {
    #   dots <- list()
    # }
    # dots.idx <- ( names(dots) != "" );
    # remaining <- sapply( setdiff(my.names, "..."), as.name)
    # if(length(remaining)) {
    #   not.dots <- lapply(remaining, eval, envir = pf)
    # } else {
    #   not.dots <- list()
    # }
    # res = list();

    # res$.fn.            = as.character( sys.call(1L)[[1L]] );
    # res$.scope.         = pf;
    # res$.keys.          = names( not.dots );
    # res$.vals.          = not.dots;                             # unname(not_dots);  # I want keys on "vals"
    # res$.dots.keys.     = names( dots[dots.idx] );
    # res$.dots.vals.     = dots[dots.idx];                       # unname(dots[dots.idx]);
    # cat("==============================================\n")
    # print(res)
    # q()

    # Obtain the arguments that have been passed to <f>
    # arguments <- as.list(match.call(definition = f, expand.dots = FALSE))
    # cat("The call:\n")
    # print(arguments)

    # Obtain the original name of <f> and then delete it from the list <arguments>
    # decor_f_name <- arguments[[1]]
    # decor_f_name <- as.list(match.call(definition = f, expand.dots = FALSE))[[1]]
    # arguments[[1]] <- NULL
    if (DEBUG) {
      cat("The information that the decorated function <", f_name, "> has is:\n", sep = "")
    }
    arguments_length <- length(arguments)
    if (DEBUG) {
      cat("Length of received arguments:", arguments_length, "\n")
    }

    # Obtain the real values of the arguments if they are symbols
    # for(ind in 1:arguments_length){
    # if(typeof(arguments[[ind]]) == "symbol"){
    #  # arguments[[ind]] <- get(arguments[[ind]])
    #  # arguments[[ind]] <- eval(parse(text = names(arguments)[[ind]]))
    #  print(arguments[[ind]])
    #  n <- 1
    #  cat("class:\n")
    #  print(class(arguments[[ind]]))
    #  cat("typeof:\n")
    #  print(typeof(arguments[[ind]]))
    #  while(class(arguments[[ind]]) == "call"){
    #    cat("n =", n, "\n")
    #    arguments[[ind]] <- eval.parent(arguments[[ind]], n = n)
    #    n <- n + 1
    #  }
    #  # arguments[[ind]] <- eval.parent(arguments[[ind]])
    # }
    #   cat("ind = ", ind, "; arguments[[", ind, "]] = ", sep = "")
    #   print(arguments[[ind]])
    #   cat("typeof(arguments[[ind]]) = ", typeof(arguments[[ind]]), "\n", sep = "")
    #   n <- 1
    #   while(typeof(arguments[[ind]]) == "symbol"){
    #     cat("n =", n, "\n")
    #     print(eval.parent(arguments[[ind]], n = n))
    #     arguments[[ind]] <- eval.parent(arguments[[ind]], n = n)
    #     n <- n + 1
    #   }
    # }
    # q()

    # Initialize the integer vector <arguments_type> according to the length of the list <arguments>
    arguments_type <- integer(arguments_length)

    # Initialize content_types
    content_types <- rep("", length = arguments_length)

    # If there are arguments from <f>, we process them
    # If not, <argument> will be an empty list and <arguments_names> will be an empty character vector
    if (arguments_length > 0) {
      if (DEBUG) {
        cat("Function <", f_name, "> has <", arguments_length, "> arguments:\n", sep = "")
      }
      # print(arguments)
      # Grep the names of the arguments
      arguments_names <- names(arguments)

      # For all the arguments, we check whether the type of the argument is basic (not object)
      # - If the type is basic, we assign the corresponding number in <arguments_type>
      # - If the type is not basic, we assign the type as 10L - FILE and serialize the object
      for (i in 1:arguments_length) {
        if (length(class(arguments[[i]])) == 1 && (class(arguments[[i]]) == "numeric" || class(arguments[[i]]) == "character")) {
          arguments_type[i] <- parType_mapping(arguments[[i]])
        } else {
          arguments_type[i] <- 10L
        }
        # If the type is 10L - FILE. we serialize the argument and we put the name of the file in the value
        if (arguments_type[i] == 10L) {
          if (length(class(arguments[[i]])) == 1 && class(arguments[[i]]) == "future_object") {
            arguments[[i]] <- arguments[[i]]$outputfile
            content_types[i] <- "future_object"
          } else {
            content_types[i] <- "object"
            obj <- arguments[[i]]
            # addr <- pryr::address(obj)
            # if(DEBUG){
            #  cat("Checking argument " , i , " with address ", addr, "\n")
            # }
            # Check if object has been accessed before. No need to serialize again
            need_serialization <- TRUE
            # if(check_key_in_hashmap(addr, accessed_objects_map)){
            #  if(DEBUG){
            #    cat("Address already in the hashmap with file:", accessed_objects_map[[addr]], "\n")
            #  }
            #  stored_val <- compss_unserialize(accessed_objects_map[[addr]])
            #  if(identical(arguments[[i]], stored_val)){
            #    if(DEBUG){
            #      cat("Address is really already in the hashmap with file:", accessed_objects_map[[addr]], "\n")
            #    }
            #    arguments[[i]] <- accessed_objects_map[[addr]]
            #    need_serialization <- FALSE
            #  }
            # }
            if (need_serialization) {
              INI.TIME <- proc.time()
              arg_ser_filename <- paste0(MASTER_WORKING_DIR, "/", arguments_names[i], "_arg[", i, "]_", UID())
              compss_serialize(object = arguments[[i]], filepath = arg_ser_filename, method = ser_method)
              SER_END.TIME <- proc.time()
              SER.TIME <- SER_END.TIME - INI.TIME
              if (DEBUG) {
                #  cat("Adding address ", addr, " in the hasmap.")
              }
              # accessed_objects_map[[addr]] <- arg_ser_filename
              arguments[[i]] <- arg_ser_filename
              if (DEBUG) {
                cat("Argument <", arguments_names[i], "> is serialized to file: <",
                  arg_ser_filename, ">; ", "Type: <", typeof(arguments[[i]]),
                  ">-<", arguments_type[i], ">;\n",
                  "Time for serialization: ", SER.TIME[3], " seconds.", "\n",
                  sep = ""
                )
              }
            }
          }
        } else {
          if (DEBUG) {
            cat("Argument <", arguments_names[i], "> is: <", arguments[[i]], ">; ",
              "Type: <", typeof(arguments[[i]]), ">-<", arguments_type[i], ">",
              "\n",
              sep = ""
            )
          }
        }
      }
    } else {
      argument <- list()
      arguments_names <- character(0)
      if (DEBUG) {
        cat("Function <", f_name, "> does not take arguments.\n", sep = "")
      }
    }

    # If there are metadata, print them
    if (length(metadata) > 0 && DEBUG) {
      cat("Metadata:\n")
      print(metadata)
    }

    # If there is a return value, we need to add another element in <arguments> for it.
    # Also, compss_types; compss_directions; compss_streams; compss_prefixes; content_types; weights; keep_renames
    # File name: return_file_UID
    if (return_value) {
      num_of_returns <- 1L
      # Create an object for the return value
      # RETURN_VALUE <- list()
      outputfile <- paste0(MASTER_WORKING_DIR, "/ReturnValue_", UID())
      # values
      arguments[[length(arguments) + 1]] <- outputfile
      # arguments_names
      arguments_names[length(arguments)] <- "RETURN_VALUE"
      # compss_types
      arguments_type <- c(arguments_type, 10L)
      # compss_directions: 0: in; 1: out (return value); 2: inout
      compss_directions <- c(rep(0L, length = arguments_length), 1)
      # compss_streams: (3,3,...,3)
      compss_streams <- rep(3L, length = arguments_length + 1)
      # compss_prefixes: "null"
      compss_prefixes <- rep("null", length = arguments_length + 1)
      # content_types: "null"
      content_types <- c(content_types, "")
      # weights:
      weights <- rep("1", length = arguments_length + 1)
      # keep_renames: If the compss_type is FILE: 1; The rest: 0. eg: c(0,1,0,1,1,1)
      keep_renames <- c(rep(0L, length = arguments_length), 1)
    } else {
      num_of_returns <- 0L
      compss_directions <- rep(0L, length = arguments_length)
      compss_streams <- rep(3L, length = arguments_length)
      compss_prefixes <- rep("null", length = arguments_length)
      # content_types <- rep("", length = arguments_length)
      weights <- rep("1", length = arguments_length)
      keep_renames <- rep(0L, length = arguments_length)
    }

    TIME2 <- proc.time()
    if (DEBUG) {
      cat("Time before register:", TIME2[3] - TIME1[3], "\n")
    }
    # Do not execute function f, invoke instead the runtime with the arg and the information
    if (!info_only) {
      register_marker <- paste0("registered_", f_name)
      if (!exists(register_marker)) {
        # cat("Registering", f_name, "\n")
        # Call register function here
        register_core_element(
          CESignature = f_name,
          ImplSignature = f_name,
          ImplConstraints = "",
          ImplType = "METHOD",
          ImplLocal = "False",
          ImplIO = "False",
          prolog = c("", "", "False"),
          epilog = c("", "", "False"),
          container = c("", "", ""),
          typeArgs = c(paste0(getwd(), "/", filename), f_name)
          # typeArgs = c("/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/temp_add3.R", f_name)
        )
        assign(register_marker, TRUE, envir = globalenv())
      }

      # Call process_task here
      process_task(
        app_id = app_id,
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
        num_returns = num_of_returns, # num_of_returns
        values = arguments, # Inputs of the function: vector # Output File name
        names = arguments_names, # List of names of the parameters: strings # A name for the return value
        compss_types = arguments_type, # Lists parType # For the output, indicate the type is a file: 10L
        compss_directions = compss_directions, # 0: in; 1: out (return value); 2: inout
        compss_streams = compss_streams, # (3,3,...,3)
        compss_prefixes = compss_prefixes, # Empty string
        content_types = content_types, # Empty string
        weights = weights, # Empty string or "[unassigned]"
        keep_renames = keep_renames # If the compss_type is FILE: 1; The rest: 0. c(0,1,0,1,1,1)
      )

      TIME3 <- proc.time()
      if (DEBUG) {
        cat("Time after register:", TIME3[3] - TIME2[3], "\n")
      }
      # If there is a return value, return the future_object which should contain outputfile as the argument
      if (return_value) {
        FO <- list(outputfile)
        names(FO)[1] <- "outputfile"
        class(FO) <- "future_object"
        return(FO)
      }
    }
  }
}

#' Return the type of <arg> in the COMPSs numbering system
parType_mapping <- function(arg) {
  switch(typeof(arg),
    "logical" = 0L,
    "CHAR" = 1L,
    "BYTE" = 2L,
    "SHORT" = 3L,
    "integer" = 4L,
    "double" = 7L,
    "character" = 8L,
    10L # FILE
  )
}

#' Generate a unique random string based on the current time
UID <- function() {
  # Get the current time
  current_time <- Sys.time()

  # Convert the time to a string representation
  time_string <- format(current_time, "%Y%m%d%H%M%S")

  # Generate a random string using the time string
  random_string <- paste0(time_string, "-", paste0(sample(c(letters, LETTERS, 0:9), 50, replace = TRUE), collapse = ""))

  return(random_string)
}

#' compss_serialize
#'
#' Internal serialization function
#'
#' @export
compss_serialize <- function(object, filepath, method) {
  if (method == "RMVL") {
    con <- RMVL::mvl_open(filepath, append = TRUE, create = TRUE)
    RMVL::mvl_write_object(con, object, name = "obj")
    RMVL::mvl_close(con)
  } else if (method == "qs") {
    qs::qsave(object, file = filepath, preset = "uncompressed")
  } else {
    stop("Unknown serialization method")
  }
}

#' compss_unserialize
#'
#' Internal unserialization function
#'
#' @export
compss_unserialize <- function(filepath, unser_method) {
  if (unser_method == "RMVL") {
    con <- RMVL::mvl_open(filepath)
    object <- RMVL::mvl2R(con$obj)
    RMVL::mvl_close(con)
    return(object)
  } else if (unser_method == "qs") {
    return(qs::qread(filepath, nthreads = 1))
  } else {
    stop("Unknown serialization method")
  }
}

#' compss_start
#'
#' Start the COMPSs runtime system
#'
#' @export
compss_start <- function() {
  start_runtime()
  MASTER_WORKING_DIR <- Get_MasterWorkingDir()
  assign("MASTER_WORKING_DIR", MASTER_WORKING_DIR, envir = .GlobalEnv)
}

#' compss_stop
#'
#' Stop the COMPSs runtime system
#'
#' @export
compss_stop <- function() {
  stop_runtime(0L)
}

#' compss_barrier
#'
#' Barrier for the COMPSs runtime system
#'
#' @param no_more_tasks Boolean.
#' @export
compss_barrier <- function(no_more_tasks = FALSE) {
  barrier(0L, no_more_tasks)
}

#' compss_wait_on
#'
#' Serialization in R and synchronize the results with the master
#'
#' @param future_obj
#' @export
compss_wait_on <- function(future_obj) {
  # if(class(future_obj) == "future_object"){
  if (length(class(future_obj)) == 1 && class(future_obj) == "future_object") {
    Get_File(0L, future_obj$outputfile)
    return_value <- compss_unserialize(future_obj$outputfile, "qs")
    return(return_value)
  } else if (length(class(future_obj)) == 1 && class(future_obj) == "list") {
    list_len <- length(future_obj)
    # return_list <- list()
    # for(i in 1:list_len){
    #  if(class(future_obj[[i]]) == "future_object"){
    #    Get_File(0L, future_obj[[i]]$outputfile)
    #    return_list[[i]] <- compss_unserialize(future_obj[[i]]$outputfile)
    #  }else{
    #    return_list[[i]] <- future_obj[[i]]
    #  }
    # }
    return_list <- lapply(
      future_obj,
      function(obj) {
        if (class(obj) == "future_object") {
          Get_File(0L, obj$outputfile)
          return(compss_unserialize(obj$outputfile, "qs"))
        } else {
          return(obj)
        }
      }
    )
    return(return_list)
  } else {
    warning("[compss_wait_on] class(future_obj):", class(future_obj), "\nNot doing anything!\n")
    return(future_obj)
  }
}

#' extrae_emit_event
#'
#' Emit EXTRAE event
#'
#' @param group Integer defining the event group.
#' @param id Integer defining the event identifier.
#' @export
extrae_emit_event <- function(group, id) {
  Extrae_event_and_counters(group, id)
}

#' extrae_ini
#'
#' Initialize EXTRAE
#'
#' @export
extrae_ini <- function() {
  Extrae_ini()
}

#' extrae_flu
#'
#' Flush EXTRAE
#'
#' @export
extrae_flu <- function() {
  Extrae_flu()
}

#' extrae_fin
#'
#' Finalize EXTRAE
#'
#' @export
extrae_fin <- function() {
  Extrae_fin()
}
