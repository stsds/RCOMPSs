# Check if the correct number of command-line arguments is provided

a <- sessionInfo()
cat("The version of R being used is:", paste0(a$R.version$major, ".", a$R.version$minor))
if (length(commandArgs(trailingOnly = TRUE)) != 3) {
  cat("Usage: Rscript script.R input_fifo output_fifo executor_id\n")
  q("no")
}

cat("RCOMPSs executor PID: ", Sys.getpid() ,"\n")
executor_id <- as.integer(commandArgs(trailingOnly = TRUE)[3])

time_since_epoch <- function() {
  x1 <- as.POSIXct(Sys.time())
  x2 <- format(x1, tz="GMT", usetz=F)
  x3 <- lubridate::ymd_hms(x2)
  epoch <- lubridate::ymd_hms('1970-01-01 00:00:00')
  time_since_epoch <- (x3 - epoch) / lubridate::dseconds()
  return(time_since_epoch)
}

RCOMPSs::extrae_ini()
if (executor_id == 0) {
  RCOMPSs::extrae_emit_event(8000666, 1)  # Sync event: for adjusting the timing
}
RCOMPSs::extrae_emit_event(9000200, 1)  # Inside worker event running
RCOMPSs::extrae_emit_event(8001003, 8)  # Define the process purpose: process worker executor event
RCOMPSs::extrae_emit_event(8001006, executor_id)  # Define the executor id

# Extract input and output FIFO paths from command-line arguments
input_fifo_path <- commandArgs(trailingOnly = TRUE)[1]
output_fifo_path <- commandArgs(trailingOnly = TRUE)[2]

# Open the input FIFO for reading
input_fifo <- fifo(input_fifo_path, open = "r", blocking=TRUE)

# Open the output FIFO for writing
output_fifo <- fifo(output_fifo_path, open = "w+", blocking=TRUE)

# Read from input FIFO and write to output FIFO
while (TRUE) {
  # Read data from input FIFO
  data <- readLines(input_fifo, n = 1)
  cat("Received:", data, "\n")
  # Check if data is empty (end of stream)
  if (length(data) == 0) {
    break
  }

  # Check if the received data is "QUIT" and exit the loop
  if (data == "QUIT") {
    break
  }

  split_data <- strsplit(data, " ")[[1]]
  tag <- split_data[1]
  if (tag == "EXECUTE_TASK"){
    RCOMPSs::extrae_emit_event(9000100, 4)
    # Print received data to the console
    task_id <- split_data[2] #(int)
    sandbox <- split_data[3]
    job_out <- split_data[4]
    job_err <- split_data[5]
    tracing <- split_data[6] #bool
    #task_id <- split_data[7]
    debug <- split_data[8] #bool
    #storage_conf <- split_data[9]
    #task_type <- split_data[10]
    module <- split_data[11]
    func <- split_data[12]
    #time_out = split_data[13] #int
    params <- split_data[14:length(split_data)]
    #other params [ number_nodes [node_names] num_threads(int) has_target(bool) return_type(type|null) num_returns num_args [args: type(int) stdio_stream prefix name value] [target: same as before] [returns]

    cat("Received task execution with id: ", task_id, ", module: ", module, ", function: ", func, " params: ", params, "\n")
    # TODO: Add here the process of the task and write end_task message
    # Writing "END_TASK" message at this m  failed task

    RCOMPSs::extrae_emit_event(9000100, 0)

    # Load the module
    cat("The module is:", module, "\n")
    tryCatch(
             {
               RCOMPSs::extrae_emit_event(9000100, 5)
               source(module)
               RCOMPSs::extrae_emit_event(9000100, 0)
               cat("Finished     source(module)", file = job_out)
               # Call the function using get()
               if (exists(func)) {

                 num_of_nodes <- as.integer(params[1])
                 cat("num_of_nodes is: ", num_of_nodes)
                 num_of_threads <- as.integer(params[2])
                 # node_name <- params[3]
                 # cus <- as.integer(params[1+num_of_nodes+2)
                 has_target <- as.logical(params[1+num_of_nodes+3])
                 return_type <- params[1+num_of_nodes+4]
                 num_of_returns <- as.integer(params[1+num_of_nodes+5])
                 num_of_args <- as.integer(params[1+num_of_nodes+6])
                 cat("num_of_args is", num_of_args)
                 #result <- get(func)(3, 4)
                 #leng_params_func <- length(formalArgs(func))
                 leng_params_func <- num_of_args - num_of_returns - has_target
                 # print(formalArgs(func))
                 cat("leng_params_func is", leng_params_func)
                 params_func_list <- list(leng_params_func)

                 first_arg_ind <- num_of_nodes + 8
                 for(i in 0:(leng_params_func-1)){
                   if(params[first_arg_ind] == "0"){
                     params_func_list[[i+1]] <- as.integer(params[first_arg_ind + 5])
                     names(params_func_list)[i+1] <- params[first_arg_ind + 3]
                     first_arg_ind <- first_arg_ind + 6
                   }else if(params[first_arg_ind] == "7"){
                     params_func_list[[i+1]] <- as.numeric(params[first_arg_ind + 5])
                     names(params_func_list)[i+1] <- params[first_arg_ind + 3]
                     first_arg_ind <- first_arg_ind + 6
                   }else if(params[first_arg_ind] == "8"){
                     num_of_words <- as.integer(params[first_arg_ind + 5])
                     vec_words <- character(num_of_words)
                     for(j in 1:num_of_words){
                       vec_words[j] <- as.character(params[first_arg_ind + 5 + j])
                     }
                     params_func_list[[i+1]] <- paste0(vec_words, collapse = " ")
                     names(params_func_list)[i+1] <- params[first_arg_ind + 3]
                     first_arg_ind <- first_arg_ind + 6 + num_of_words
                   }else if(params[first_arg_ind] == "10"){
                     content_type <- as.character(params[first_arg_ind + 4])
                     # print(paste0("The content type is: ", content_type, "\n"))
                     path_value <- as.character(params[first_arg_ind + 5])
                     path_value <- strsplit(path_value, ":")[[1]]
                     path_value <- path_value[length(path_value)]
                     if(content_type != "null"){
                       # print(paste0("The path value is: ", path_value, "\n"))
                       #params_func_list[[i+1]] <- compss_unserialize(filepath = path_value)
                       #params_func_list[[i+1]] <- readRDS(file = path_value)
                       # ext <- strsplit(path_value, "[.]")[[1]]
                       # ext <- ext[length(ext)]
                       # con <- file(description = path_value, open = "rb")
                       # par_raw <- readBin(con, what = raw(), n = file.info(path_value)$size)
                       # params_func_list[[i+1]] <- unserialize(connection = par_raw)
                       # close(con)
                       TIME_UNSER <- proc.time()
                       RCOMPSs::extrae_emit_event(9000100, 8)
                       params_func_list[[i+1]] <- RCOMPSs::compss_unserialize(path_value)
                       RCOMPSs::extrae_emit_event(9000100, 0)
                       TIME_UNSER <- proc.time() - TIME_UNSER
                       cat("RCOMPSs::compss_unserialize TIME:", TIME_UNSER[3], "seconds\n")
                       # print("params_func_list\n")
                       # print(params_func_list[i+1])
                     }else{
                       params_func_list[[i+1]] <- path_value
                     }
                     names(params_func_list)[i+1] <- params[first_arg_ind + 3]
                     first_arg_ind <- first_arg_ind + 6
                   }else{
                     cat("i = ", i)
                     cat("Non-supported type: ", params[first_arg_ind + 6*i])
                   }
                 }
                 # print("params_func_list:\n")
                 # print(params_func_list)
                 TIME_CALL <- proc.time()
                 RCOMPSs::extrae_emit_event(9000100, 6)
                 result <- do.call(func, params_func_list)
                 RCOMPSs::extrae_emit_event(9000100, 0)
                 TIME_CALL <- proc.time() - TIME_CALL
                 cat("do.call TIME:", TIME_CALL[3], "seconds\n")
                 cat("num_of_returns:", num_of_returns, "\n")
                 if(num_of_returns > 0){
                   path_return_value <- as.character(params[first_arg_ind + 5])
                   path_return_value <- strsplit(path_return_value, ":")[[1]]
                   path_return_value <- path_return_value[length(path_return_value)]
                   # compss_serialize(object = result, filepath = path_return_value)
                   # con <- file(description = path_return_value, open = "wb")
                   # x <- serialize(object = result, connection = NULL)
                   # writeBin(x, con)
                   # close(con)
                   TIME_SER <- proc.time()
                   RCOMPSs::extrae_emit_event(9000100, 9)
                   RCOMPSs::compss_serialize(result, path_return_value)
                   RCOMPSs::extrae_emit_event(9000100, 0)
                   TIME_SER <- proc.time() - TIME_SER
                   cat("RCOMPSs::compss_serialize TIME:", TIME_SER[3], "seconds\n")
                   cat("The path is: ", path_return_value)
                 }
                 # print("The results is:\n")
                 # print(result)
                 RCOMPSs::extrae_emit_event(9000100, 11)
                 cat("END_TASK", task_id, 0, file = output_fifo, "\n")
                 RCOMPSs::extrae_emit_event(9000100, 0)
               } else {
                 cat("Function", function_name, "does not exist")
                 RCOMPSs::extrae_emit_event(9000100, 13)
                 cat("END_TASK", task_id, 1, file = output_fifo, "\n")
                 RCOMPSs::extrae_emit_event(9000100, 0)
               }
             }, error = function(e) {
               # Handle the error
               cat("Error:", e$message, file = job_err)
               print(paste("Error:", e$message))
               traceback()
               RCOMPSs::extrae_emit_event(9000100, 13)
               cat("END_TASK", task_id, 1, file = output_fifo, "\n")
               RCOMPSs::extrae_emit_event(9000100, 0)
             })

    # cat("END_TASK", task_id, 1, file = output_fifo, "\n")
  } else {
    cat("Received:", data, "\n")
  }
}

RCOMPSs::extrae_emit_event(9000200, 0)  # Inside worker event not running
if (executor_id == 0) {
  RCOMPSs::extrae_emit_event(8000666, 0)  # Sync event: for adjusting the timing
  RCOMPSs::extrae_emit_event(8000666, time_since_epoch())  # Sync event: for adjusting the timing
  RCOMPSs::extrae_emit_event(8000666, 0)  # Sync event: for adjusting the timing
}
RCOMPSs::extrae_flu()
RCOMPSs::extrae_fin()

# Close the FIFOs
close(input_fifo)
close(output_fifo)
#
