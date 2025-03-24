flush.console()
Sys.sleep(1)

args <- commandArgs(trailingOnly = TRUE)

use_merge2 <- FALSE

Minimize <- FALSE
# Parse arguments
if(length(args) >= 1){
  for (i in 1:length(args)) {
    if (args[i] == "-M") {
      Minimize <- TRUE
    } else if (args[i] == "--Minimize") {
      Minimize <- TRUE
    }
  }
}

# Source necessary functions
if(!Minimize){
  cat("Sourcing necessary functions ... ")
}
source("tasks_kmeans.R")
source("functions_kmeans.R")
if(!Minimize){
  cat("Done.\n")
}

if(!Minimize){
  cat("Getting parameters ... ")
}
params <- parse_arguments(Minimize)
if(!Minimize){
  print_parameters(params)
}
attach(params)
if(!Minimize){
  cat("Done.\n")
}

set.seed(seed)

if(use_RCOMPSs){
  require(RCOMPSs)

  # Initiate COMPSs
  if(!Minimize){
    cat("Starting COMPSs ... ")
  }
  compss_start()
  cat("COMPSs started!\n")
  flush.console()
  if(!Minimize){
    cat("Done.\n")
  }

  # Define the tasks
  if(!Minimize){
    cat("Defining the tasks ... ")
  }
  task.fill_fragment <- task(fill_fragment, "tasks_kmeans.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.partial_sum <- task(partial_sum, "tasks_kmeans.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.merge <- task(merge, "tasks_kmeans.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.merge2 <- task(merge2, "tasks_kmeans.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  if(!Minimize){
    cat("Done.\n")
  }
}else{
  if(!Minimize){
    cat("Sequencial execution without RCOMPSs!\n")
  }
}

# Look at the kmeans_frag for the KMeans function.
# This code is used for experimental purposes.
# I.e it generates random data from some parameters that determine the size,
# dimensionality and etc and returns the elapsed time.

for(replicate in 1:2){

  start_time <- proc.time()

  # Generate the data
  if(!Minimize){
    cat("Generating data replicate", replicate, "... ")
  }
  # Prevent infinite loops
  points_per_fragment <- max(1, numpoints %/% num_fragments)
  # Generate cluster central points
  true_centres <- matrix(runif(num_centres * dimensions), 
                         nrow = num_centres, ncol = dimensions)

  fragment_list <- list()
  if(use_RCOMPSs){
    for (f in 1:num_fragments) {
      params_fill_fragment <- list(true_centres, points_per_fragment, mode)
      fragment_list[[f]] <- task.fill_fragment(params_fill_fragment)
    }
    #fragment_list <- compss_wait_on(fragment_list)
  }else{
    for (f in 1:num_fragments) {
      params_fill_fragment <- list(true_centres, points_per_fragment, mode)
      fragment_list[[f]] <- fill_fragment(params_fill_fragment)
    }
  }
  initialization_time <- proc.time()
  if(!Minimize){
    cat("Done.\n")
  }
  #print(fragment_mat)

  # Run kmeans
  if(use_R_default){
    fragment_mat <- do.call(rbind, fragment_list)
    centres <- kmeans(fragment_mat[, 1:dimensions], num_centres, iterations)
  }else{
    centres <- kmeans_frag(
                           fragment_list = fragment_list,
                           num_centres = num_centres,
                           iterations = iterations,
                           epsilon = epsilon,
                           arity = arity
    )
  }

  kmeans_time <- proc.time()

  Initialization_time <- initialization_time[3] - start_time[3]
  Kmeans_time <- kmeans_time[3] - initialization_time[3]
  Total_time <- proc.time()[3] - start_time[3]

  if(!Minimize){
    cat("-----------------------------------------\n")
    cat("-------------- RESULTS ------------------\n")
    cat("-----------------------------------------\n")
    cat("Initialization time:", Initialization_time, "seconds\n")
    cat("Kmeans time:", Kmeans_time, "seconds\n")
    cat("Total time:", Total_time, "seconds\n")
    cat("-----------------------------------------\n")
    # Sort the results and compare
    ind_centres <- sort(centres[,1], index.return = TRUE)$ix
    ind_true_centres <- sort(true_centres[,1], index.return = TRUE)$ix
    cat("CENTRES\n")
    print(centres[ind_centres,])
    cat("TRUE CENTRES\n")
    print(true_centres[ind_true_centres,])
    cat("-----------------------------------------\n")
  }

  if(use_R_default){
    type <- "R_default"
  }else if(use_RCOMPSs){
    type <- "RCOMPSs"
  }else{
    type <- "R_sequential"
  }
  cat("KMEANS_RESULTS,",
      seed, ",",
      numpoints, ",",
      dimensions, ",",
      num_centres, ",",
      num_fragments, ",",
      mode, ",",
      iterations, ",",
      epsilon, ",",
      arity, ",",
      type, ",",
      paste(R.version$major, R.version$minor, sep="."), ",",
      Initialization_time, ",",
      Kmeans_time, ",",
      Total_time, ",",
      replicate,
      "\n", sep = ""
  )

}

if(use_RCOMPSs){
  if(needs_plot) fragment_list <- compss_wait_on(fragment_list)
  compss_stop()
}

# Plot the data
if(needs_plot){
  pdf(paste0("kmeans", Sys.time(), ".pdf"))
  #pdf("/scratch/zhanx0q/RCOMPSs5/COMPSs/Bindings/RCOMPSs/examples/kmeans/kmeans.pdf")
  par(bg = "white")
  fragment_mat <- do.call(rbind, fragment_list)
  plot(fragment_mat, col = "blue")
  points(centres, col = "red", pch = 8)
  dev.off()
}
