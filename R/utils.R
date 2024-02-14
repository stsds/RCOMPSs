#' task
#'
#' This function is the decorator for tasks.
#'
#' @param f The function to be executed.
#' @param f_dir Absolute directory of the file where f is defined.
#' @param info_only Boolean. Whether the run is to print the information only.
#' @param ... Metadata.
#' @return The decorated function
#' @export
task <- function(f, filename, return_value = FALSE, info_only = FALSE, ...){
  metadata <- list(...)
  f_name <- as.character(as.list(match.call())$f)
  function(...){
    app_id <- 0L # TODO: generate automatically
    arguments <- as.list(match.call(definition = f, expand.dots = FALSE))
    print(arguments)
    decor_f_name <- arguments[[1]]
    arguments[[1]] <- NULL
    cat("The information that the decorated function <", decor_f_name, "> has is:\n", sep = "")
    arguments_length <- length(arguments)
    cat("Length of received arguments:", arguments_length, "\n")
    arguments_type <- integer(arguments_length)
    if(arguments_length > 0){
      cat("Function <", f_name, "> has <", arguments_length, "> arguments:\n", sep = "")
      arguments_names <- names(arguments)
      for(i in 1:arguments_length){
        # cat("arguments[[", i, "]] is ", arguments[[i]], "\n", sep = "")
        arguments_type[i] <- parType_mapping(arguments[[i]])
        # type - FILE. Serialize them. in the value, we put the name of the file.
        if(arguments_type[i] == 10L){
          arg_ser_filename <- paste0("UID_", app_id, "_arg[", i, "]_", arguments_names[i])
          serialize(object = arguments[[i]],
                    connection = file(description = arg_ser_filename,
                                      open = "w"))
          close(arg_ser_filename)
          arguments[[i]] <- arg_ser_filename
          cat("Argument <", arguments_names[i], "> is serialized to file: <", arg_ser_filename, ">; ",
              "Type: <", typeof(arguments[[i]]), ">-<", arguments_type[i], ">",
              "\n", sep = "")
        }else{
          cat("Argument <", arguments_names[i], "> is: <", arguments[[i]], ">; ",
              "Type: <", typeof(arguments[[i]]), ">-<", arguments_type[i], ">",
              "\n", sep = "")
        }
      }
    }else{
      argument <- list()
      arguments_names <- character(0)
      cat("Function <", f_name, "> does not take arguments.\n", sep = "")
    }
    if(length(metadata) > 0){
      cat("Metadata:\n")
      print(metadata)
    }
    # If there is a return we need to add another argument for it.
    # compss_types; compss_directions; compss_streams; compss_prefixes; content_types; weights; keep_renames
    # File name: return_file_UID
    if(return_value){
      num_of_returns <- 1L
      # Create an object for the return value
      # RETURN_VALUE <- list()
      outputfile <- paste0("UID_", app_id, "_outputfile")
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
      content_types <-  rep("", length = arguments_length + 1)
      # weights:
      weights <- rep("1", length = arguments_length + 1)
      # keep_renames: If the compss_type is FILE: 1; The rest: 0. eg: c(0,1,0,1,1,1)
      keep_renames <- c(rep(0L, length = arguments_length), 1)
    }else{
      num_of_returns <- 0L
      compss_directions <- rep(0L, length = arguments_length)
      compss_streams <- rep(3L, length = arguments_length)
      compss_prefixes <- rep("null", length = arguments_length)
      content_types <- rep("", length = arguments_length)
      weights <- rep("1", length = arguments_length)
      keep_renames <- rep(0L, length = arguments_length)
    }

    cat("Current working directory is:", getwd(), "\n")
    # Do not execute function f, invoke instead the runtime with the arg and the information
    if(!info_only){
      # Call register function here
      register_core_element(CESignature = f_name,
                            ImplSignature = f_name,
                            ImplConstraints = "",
                            ImplType = "METHOD",
                            ImplLocal = "False",
                            ImplIO = "False",
                            prolog = c("", "", "False"),
                            epilog = c("", "", "False"),
                            container = c("", "", ""),
                            typeArgs = c(paste0(getwd(), "/", filename, ".R"), f_name)
                            # typeArgs = c("/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/temp_add3.R", f_name)
                            )

      # Call process_task here
      process_task(app_id = app_id,
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
     
      # If there is a return value, return the future_object which should contain outputfile as the argument
      if(return_value){
        FO <- list(outputfile)
        class(FO) <- "future_object"
        return(FO)
      }
    }
  }
}

parType_mapping <- function(arg){
  switch (typeof(arg),
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
