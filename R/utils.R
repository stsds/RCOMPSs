#' task
#'
#' This function is the decorator for tasks.
#'
#' @param f The function to be executed.
#' @param ... Metadata.
#' @return The decorated function
#' @export
task <- function(f, info_only = FALSE, ...){
  metadata <- list(...)
  f_name <- as.character(as.list(match.call())$f)
  function(...){
    arguments <- as.list(match.call(definition = f, expand.dots = FALSE))
    decor_f_name <- arguments[[1]]
    arguments[[1]] <- NULL
    cat("The information that the decorated function <", decor_f_name, "> has is:\n", sep = "")
    arguments_length <- length(arguments)
    arguments_type <- integer(arguments_length)
    if(arguments_length > 0){
      cat("Function <", f_name, "> has <", arguments_length, "> arguments:\n", sep = "")
      arguments_names <- names(arguments)
      for(i in 1:arguments_length){
        arguments_type[i] <- parType_mapping(arguments[[i]])
        cat("Argument <", arguments_names[i], "> is: <", arguments[[i]], ">; ",
            "Type: <", typeof(arguments[[i]]), ">-<", arguments_type[i], ">",
            "\n", sep = "")
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
                            typeArgs = c("filename", f_name))
  
      # Call process_task here
      process_task(app_id = 1L, 
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
                   num_returns = 0L,
                   values = arguments, # Inputs of the function: vector
                   names = arguments_names, # List of names of the parameters: strings
                   compss_types = arguments_type, # Lists parType
                   compss_directions = rep(0L, length = arguments_length), # 0: in; 1: out; 2: inout
                   compss_streams = rep(3L, length = arguments_length), # (3,3,...,3)
                   compss_prefixes = rep("null", length = arguments_length), # Empty string
                   content_types = rep("", length = arguments_length), # Empty string
                   weights = rep("1", length = arguments_length), # Empty string or "[unassigned]"
                   keep_renames = rep(0L, length = arguments_length) # If the compss_type is FILE: 1; The rest: 0. c(0,1,0,1,1,1)
      ) 
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
    "character" = 8L
  )
}
