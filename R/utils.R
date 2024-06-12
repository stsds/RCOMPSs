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
task <- function(f, filename, return_value = FALSE, info_only = FALSE, ...){
  
  TIME1 <- proc.time()
  
  # Convert all the metadata into a list
  metadata <- list(...)
  
  # Obtain the name of the function we are decorating
  f_name <- as.character(as.list(match.call())$f)
  
  # If we have NOT already got <MASTER_WORKING_DIR>, assign <MASTER_WORKING_DIR> to current working directory
  if( !( "MASTER_WORKING_DIR" %in% ls(envir = globalenv()) ) ){
    MASTER_WORKING_DIR <- get_wd()
  }
  
  # This function will be returned as the decorated version of <f>
  function(...){
    library(pryr)    
    # The application id is always 0L
    app_id <- 0L
    
    # Obtain the arguments that have been passed to <f>
    arguments <- as.list(match.call(definition = f, expand.dots = FALSE))
    
    # Obtain the original name of <f> and then delete it from the list <arguments>
    decor_f_name <- arguments[[1]]
    arguments[[1]] <- NULL
    cat("The information that the decorated function <", decor_f_name, "> has is:\n", sep = "")
    arguments_length <- length(arguments)
    cat("Length of received arguments:", arguments_length, "\n")
    
    # Obtain the real values of the arguments if they are symbols
    for(ind in 1:arguments_length){
      if(typeof(arguments[[ind]]) == "symbol"){
        arguments[[ind]] <- get(arguments[[ind]])
      }
    }
    
    # Initialize the integer vector <arguments_type> according to the length of the list <arguments>
    arguments_type <- integer(arguments_length)
    
    # Initialize content_types
    content_types <-  rep("", length = arguments_length)
    
    # If there are arguments from <f>, we process them
    # If not, <argument> will be an empty list and <arguments_names> will be an empty character vector
    if(arguments_length > 0){
      cat("Function <", f_name, "> has <", arguments_length, "> arguments:\n", sep = "")
      # print(arguments)
      # Grep the names of the arguments
      arguments_names <- names(arguments)
      
      # For all the arguments, we check whether the type of the argument is basic (not object)
      # - If the type is basic, we assign the corresponding number in <arguments_type>
      # - If the type is not basic, we assign the type as 10L - FILE and serialize the object
      for(i in 1:arguments_length){
        if(length(class(arguments[[i]])) == 1 && (class(arguments[[i]]) == "numeric" || class(arguments[[i]]) == "character")){
          arguments_type[i] <- parType_mapping(arguments[[i]])
        }else{
          arguments_type[i] <- 10L
        }
        # If the type is 10L - FILE. we serialize the argument and we put the name of the file in the value
        if(arguments_type[i] == 10L){
          if(length(class(arguments[[i]])) == 1 && class(arguments[[i]]) == "future_object"){
            arguments[[i]] <- arguments[[i]]$outputfile
            content_types[i] <- "future_object"
          }else{
            content_types[i] <- "object"
	    obj <- arguments[[i]]
	    addr <- address(obj)
	    cat("Checking argument " , i , " with address ", addr)
	    # Check if object has been accessed before. No need to serialize again
	    if(check_key_in_hashmap(addr, accessed_objects_map)){
            	cat("Address already in the hasmap.") 
		arguments[[i]] <- accessed_objects_map[[addr]]
	    }else{
            	INI.TIME <- proc.time()
	        arg_ser_filename <- paste0(MASTER_WORKING_DIR, arguments_names[i], "_arg[", i, "]_",  UID())
                compss_serialize(object = arguments[[i]], arg_ser_filename)
                # arg_ser <- serialize(object = arguments[[i]], connection = NULL)
                # con <- file(description = arg_ser_filename, open = "wb")
                # writeBin(object = arg_ser, con = con)
                # close(con)
                # compss_serialize(object = arguments[[i]], filepath = arg_ser_filename)
            	SER_END.TIME <- proc.time()
            	SER.TIME <- SER_END.TIME - INI.TIME
	    	con <- file(description = arg_ser_filename, open = "wb")
            	writeBin(object = arg_ser, con = con)
            	close(con)
            	# compss_serialize(object = arguments[[i]], filepath = arg_ser_filename)
            	WRITE.TIME <- proc.time() - SER_END.TIME
		cat("Adding address ", addr, " in the hasmap.")
		accessed_objects_map[[addr]] <- arg_ser_filename
                arguments[[i]] <- arg_ser_filename
                cat("Argument <", arguments_names[i], "> is serialized to file: <", 
		    arg_ser_filename, ">; ", "Type: <", typeof(arguments[[i]]), 
		    ">-<", arguments_type[i], ">;\n", 
		    "Time for serialization: ", SER.TIME[3], " seconds.",
		    "Time for writing: ", WRITE.TIME[3], " seconds.", "\n", sep = "")
	    }
          }
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
    
    # If there are metadata, print them
    if(length(metadata) > 0){
      cat("Metadata:\n")
      print(metadata)
    }
    
    # If there is a return value, we need to add another element in <arguments> for it.
    # Also, compss_types; compss_directions; compss_streams; compss_prefixes; content_types; weights; keep_renames
    # File name: return_file_UID
    if(return_value){
      num_of_returns <- 1L
      # Create an object for the return value
      # RETURN_VALUE <- list()
      outputfile <- paste0(MASTER_WORKING_DIR, "ReturnValue_", UID())
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
      content_types <-  c(content_types, "")
      # weights:
      weights <- rep("1", length = arguments_length + 1)
      # keep_renames: If the compss_type is FILE: 1; The rest: 0. eg: c(0,1,0,1,1,1)
      keep_renames <- c(rep(0L, length = arguments_length), 1)
    }else{
      num_of_returns <- 0L
      compss_directions <- rep(0L, length = arguments_length)
      compss_streams <- rep(3L, length = arguments_length)
      compss_prefixes <- rep("null", length = arguments_length)
      # content_types <- rep("", length = arguments_length)
      weights <- rep("1", length = arguments_length)
      keep_renames <- rep(0L, length = arguments_length)
    }

    TIME2 <- proc.time()
    cat("Time before register:", TIME2[3] - TIME1[3], "\n")
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
                            typeArgs = c(paste0(getwd(), "/", filename), f_name)
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
     
      TIME3 <- proc.time()
      cat("Time after register:", TIME3[3] - TIME2[3], "\n")
      # If there is a return value, return the future_object which should contain outputfile as the argument
      if(return_value){
        FO <- list(outputfile)
        names(FO)[1] <- "outputfile"
        class(FO) <- "future_object"
        return(FO)
      }
    }
  }
}

#' Return the type of <arg> in the COMPSs numbering system
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

#' Generate a unique random string based on the current time
UID <- function() {
  # Get the current time
  current_time <- Sys.time()
  
  # Convert the time to a string representation
  time_string <- format(current_time, "%Y%m%d%H%M%S")
  
  # Generate a random string using the time string
  random_string <- paste0(time_string, paste0(sample(letters, 50, replace = TRUE), collapse = ""))
  
  return(random_string)
}

#' compss_serialize
#' 
#' Internal serialization function
#' 
#' @export
compss_serialize <- function(object, filepath){
  con <- RMVL::mvl_open(filepath, append = TRUE, create = TRUE)
  RMVL::mvl_write_object(con, object, name = "obj")
  RMVL::mvl_close(con)
}

#' compss_unserialize
#'  
#' Internal unserialization function
#' 
#' @export
compss_unserialize <- function(filepath){
  con <- RMVL::mvl_open(filepath)
  object <- RMVL::mvl2R(con$obj)
  RMVL::mvl_close(con)
  return(object)
}

#' compss_start
#'
#' Start the COMPSs runtime system
#'
#' @export
compss_start <- function(){
  start_runtime()
  MASTER_WORKING_DIR <- Get_MasterWorkingDir()
  assign("MASTER_WORKING_DIR", MASTER_WORKING_DIR, envir = .GlobalEnv)
}

#' compss_stop
#'
#' Stop the COMPSs runtime system
#'
#' @export
compss_stop <- function(){
  stop_runtime(0L)
}

#' compss_barrier
#'
#' Barrier for the COMPSs runtime system
#'
#' @param no_more_tasks Boolean.
#' @export
compss_barrier <- function(no_more_tasks = FALSE){
  barrier(0L, no_more_tasks)
}

#' compss_wait_on
#'
#' Serialization in R and synchronize the results with the master
#'
#' @param future_obj 
#' @export
compss_wait_on <- function(future_obj){
  if(class(future_obj) != "future_object"){
    return(future_obj)
  }else{
    Get_File(0L, future_obj$outputfile)
    # ext <- strsplit(future_obj$outputfile, "[.]")[[1]]
    # ext <- ext[length(ext)]
    # con <- file(description = future_obj$outputfile, open = "rb")
    # res <- readBin(con, what = raw(), n = file.info(future_obj$outputfile)$size)
    # return_value <- unserialize(connection = res)
    # close(con)
    return_value <- compss_unserialize(future_obj$outputfile)
    return(return_value)
  }
}
