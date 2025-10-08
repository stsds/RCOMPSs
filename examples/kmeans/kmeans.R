# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

# @file kmeans.R
# @brief This file contains the main application of K-means clustering
# @version 1.0
# @author Xiran Zhang
# @date 2025-04-28

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

set.seed(seed)

for(replicate in 1:tot_rep){

  start_time <- proc.time()
  # Centres is usually a very small matrix, so it is affordable to have it in
  # the master.
  # TODO: The centres should be generated in a way that at least there is one point in the fragment that is close to the centre.
  centres <- matrix(runif(num_centres * dimensions), nrow = num_centres, ncol = dimensions)
  if(DEBUG$kmeans_frag){
        cat("Initialized centres:\n")
        print(centres)
      }

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
      fragment_list[[f]] <- task.fill_fragment(true_centres, points_per_fragment, mode, iseed = seed + f)
    }
    #fragment_list <- compss_wait_on(fragment_list)
  }else{
    for (f in 1:num_fragments) {
      fragment_list[[f]] <- fill_fragment(true_centres, points_per_fragment, mode, iseed = seed + f)
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
    kmeans_res <- kmeans_frag(
                            centres = centres,
                           fragment_list = fragment_list,
                           num_centres = num_centres,
                           iterations = iterations,
                           epsilon = epsilon,
                           arity = arity
    )
    rm(centres)
    centres <- kmeans_res[["centres"]]
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
  if(Minimize){
    cat(paste0("KMEANS_", type, ","),
        seed, ",",
        numpoints, ",",
        dimensions, ",",
        num_centres, ",",
        num_fragments, ",",
        mode, ",",
        kmeans_res[["num_iter"]], ",",
        kmeans_res[["converged"]], ",",
        epsilon, ",",
        arity, ",",
        type, ",",
        paste(R.version$major, R.version$minor, sep="."), ",",
        Initialization_time, ",",
        Kmeans_time, ",",
        Total_time, ",",
        replicate, ",",
        tot_rep,
        "\n", sep = ""
    )
  }
  rm(centres, true_centres, fragment_list, kmeans_res)
  gc()
}

if(use_RCOMPSs){
  if(needs_plot) fragment_list <- compss_wait_on(fragment_list)
  #compss_stop()
}

# Plot the data
if(needs_plot){
  pdf(paste0("kmeans", Sys.time(), ".pdf"))
  par(bg = "white")
  fragment_mat <- do.call(rbind, fragment_list)
  plot(fragment_mat, col = "blue", xlab = "x", ylab = "y")
  points(centres, col = "red", pch = 8)
  dev.off()
}
