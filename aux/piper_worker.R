# Parallel used for loading imports concurrently before starting the worker.
library(parallel)
library(doParallel)

LIBPATHS <- .libPaths()

###############################################################
##################### PRELOAD LIBRARIES #######################
###############################################################
# Load dinamically the imports before running the worker
load_libraries_in_parallel <- function(libraries_list) {
  num_cores <- detectCores() # Get the amount of available cores
  cl <- makeCluster(num_cores) # Create a cluster of processes
  registerDoParallel(cl) # Register the cluster

  # Function to load dinamically a library
  load_library <- function(library) {
    tryCatch({
      dyn.load(paste0(LIBPATHS, "/", library, "/libs/", library, ".so"))
      print(paste(library, " successfully loaded!"))
    }, error = function(e) {
      stop(paste("Error loading library:", library, ":", e$message))
    })
  }

  # Apply the function load_library to all elements in parallel
  result <- mclapply(libraries_list, load_library)

  # Deregister the cluster and finalize the processes
  stopCluster(cl)
}

nombre_variable <- "PRELOAD_R_LIBRARIES"
libraries <- Sys.getenv(nombre_variable)
print("Preloading R libraries")
if (!is.null(libraries)){
    print(paste(libraries, "libraries to be loaded"))
    # e.g.- libraries <- "tidyverse,lubridate,dplyr"
    # Split the names of the libraries by comma
    libraries_list <- strsplit(libraries, ",")[[1]]
    # Load the libraries in multiple processes
    load_libraries_in_parallel(libraries_list)
} else {
    print("No libraries to be preloaded")
}
###############################################################
################### END PRELOAD LIBRARIES #####################
###############################################################

###############################################################
####################### MAIN R SCRIPT #########################
###############################################################
# print("Starting R Worker!")
# Get command-line arguments
args <- commandArgs(TRUE)
print(paste("Parameters:", paste(args, collapse=" ")))

args_list <- as.list(args)

# Even positions - CMDpipes
even_positions <- seq(2, length(args_list), by = 2)
even_args <- args_list[even_positions]

# Odd positions - RESULTpipes
odd_positions <- seq(1, length(args_list), by = 2)
odd_args <- args_list[odd_positions]

pipe_pairs <- Map(c, odd_args, even_args)

# Add a loop creating subprocesses (parallel processses) for each executor
position = 0
for i in pipe_pairs:
    start_process(executor.R, i[0], i[1], position)  # launch independen processes from R
    position += 1

wait for all processes (they will be killed when the execution finishes)

#print("Pipe_pairs:")
#print(pipe_pairs)
#print(pares[[1]][[2]])

# TODO: hacer un bucle que levante subprocesos a partir de executor R pasando
# su pareja de pipes y el entero que le toca.
# Al final, devolver una lista de pares con el entero y su pid.


###############################################################
###############################################################
###############################################################
