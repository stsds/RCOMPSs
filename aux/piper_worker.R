# ##################################### #
# ########## RCOMPSs WORKER ########### #
# ##################################### #

# Foreach is used to start the executors.
library(foreach)
# Preloading RCOMPSs to boost the executors
library(RCOMPSs)

LIBPATHS <- .libPaths()

# ###############################################################
# ##################### PRELOAD LIBRARIES #######################
# ###############################################################
# # Load dinamically the imports before running the worker
# load_libraries_in_parallel <- function(libraries_list) {
#   num_cores <- parallel::detectCores() - 1 # Get the amount of available cores
#   cl <- parallel::makeCluster(num_cores, outfile="") # Create a cluster of processes
#   doParallel::registerDoParallel(cl) # Register the cluster
#
#   # Function to load dinamically a library
#   load_library <- function(library) {
#     tryCatch({
#       dyn.load(paste0(LIBPATHS, "/", library, "/libs/", library, ".so"))
#       print(paste(library, " successfully loaded!"))
#     }, error = function(e) {
#       stop(paste("Error loading library:", library, ":", e$message))
#     })
#   }
#
#   # Apply the function load_library to all elements in parallel
#   result <- parallel::mclapply(libraries_list, load_library)
#   # Deregister the cluster and finalize the processes
#   parallel::stopCluster(cl)
# }
#
# nombre_variable <- "PRELOAD_R_LIBRARIES"
# libraries <- Sys.getenv(nombre_variable)
# print("Preloading R libraries")
# if (!is.null(libraries)){
#     print(paste(libraries, "libraries to be loaded"))
#     # e.g.- libraries <- "tidyverse,lubridate,dplyr"
#     # Split the names of the libraries by comma
#     libraries_list <- strsplit(libraries, ",")[[1]]
#     # Load the libraries in multiple processes
#     load_libraries_in_parallel(libraries_list)
# } else {
#     print("No libraries to be preloaded")
# }
# ###############################################################
# ################### END PRELOAD LIBRARIES #####################
# ###############################################################

time_since_epoch <- function() {
  x1 <- as.POSIXct(Sys.time())
  x2 <- format(x1, tz="GMT", usetz=F)
  x3 <- lubridate::ymd_hms(x2)
  epoch <- lubridate::ymd_hms('1970-01-01 00:00:00')
  time_since_epoch <- (x3 - epoch) / lubridate::dseconds()
  return(time_since_epoch)
}

###############################################################
####################### MAIN R SCRIPT #########################
###############################################################
print("Starting R Worker!")

RCOMPSs::extrae_ini()
RCOMPSs::extrae_emit_event(8000666, 1)  # Sync event: for adjusting the timing

# Get command-line arguments
args <- commandArgs(TRUE)
print(paste("Parameters:", paste(args, collapse=" ")))

args_list <- as.list(args)
current_path <- args_list[1]
args_list <- args_list[-1]  # Remove current dir
source(paste(current_path, "executor.R", sep="/"))

# Even positions - CMDpipes
even_positions <- seq(2, length(args_list), by = 2)
even_args <- args_list[even_positions]

# Odd positions - RESULTpipes
odd_positions <- seq(1, length(args_list), by = 2)
odd_args <- args_list[odd_positions]

pipe_pairs <- Map(c, odd_args, even_args)

# num_cores <- parallel::detectCores() / 2  # Use one all total cores
num_cores <- length(pipe_pairs)
cl <- parallel::makeCluster(num_cores, outfile="")
doParallel::registerDoParallel(cl)
pipe_pids <- integer(length(pipe_pairs))
foreach(position = 1:length(pipe_pairs), .verbose=TRUE, .combine = 'c') %dopar% {
  pipe_pids[position] <- Sys.getpid()
  executor(pipe_pairs[[position]][1], pipe_pairs[[position]][2], position - 1)
}

RCOMPSs::extrae_emit_event(8000666, 0)  # Sync event: for adjusting the timing
RCOMPSs::extrae_emit_event(8000666, time_since_epoch())  # Sync event: for adjusting the timing
RCOMPSs::extrae_emit_event(8000666, 0)  # Sync event: for adjusting the timing
RCOMPSs::extrae_flu()
RCOMPSs::extrae_fin()

parallel::stopCluster(cl)

###############################################################
###############################################################
###############################################################
