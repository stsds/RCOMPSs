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

Minimize <- any(args %in% c("-M","--Minimize"))

# Source necessary functions
if(!Minimize){
  cat("Sourcing necessary functions ... ")
}
source("RCOMPSs_bigmemory_tasks_kmeans.R")
source("RCOMPSs_bigmemory_functions_kmeans.R")
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
  task.fill_fragment <- task(fill_fragment, "RCOMPSs_bigmemory_tasks_kmeans.R", info_only = FALSE, return_value = TRUE, return_type = "element", DEBUG = FALSE)
  task.partial_sum <- task(partial_sum, "RCOMPSs_bigmemory_tasks_kmeans.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.merge <- task(merge, "RCOMPSs_bigmemory_tasks_kmeans.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.merge2 <- task(merge2, "RCOMPSs_bigmemory_tasks_kmeans.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
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

      # --- Pre-allocate the Shared Memory Matrix ---
  if(!Minimize) cat("Creating shared big.matrix for data generation...\n")
  bm_dir <- tempdir()
  bm_base <- sprintf("bm_%s_%d", format(Sys.time(), "%Y%m%d%H%M%S"), replicate)
  all_points <- bigmemory::filebacked.big.matrix(
    nrow = numpoints, ncol = dimensions, type = "double",
    backingpath = bm_dir,
    backingfile = paste0(bm_base, ".bin"),
    descriptorfile = paste0(bm_base, ".desc")
  )
  all_points_desc <- bigmemory::describe(all_points) # A descriptor to find the matrix

  # Generate the data
  if(!Minimize){
    cat("Generating data replicate", replicate, "... ")
  }
  # Prevent infinite loops
  points_per_fragment <- as.integer(max(1, numpoints %/% num_fragments))
  # Generate cluster central points
  true_centres <- matrix(runif(num_centres * dimensions), 
                         nrow = num_centres, ncol = dimensions)

  fragment_indicator <- vector("logical", num_fragments)
  fragment_indicator <- sapply(1:num_fragments, function(f) {
    task.fill_fragment(true_centres, points_per_fragment, mode, iseed = as.integer(seed + f),
                        bigmatrix_desc = all_points_desc, 
                        start_row = as.integer((f - 1) * points_per_fragment + 1), 
                        end_row = as.integer(f * points_per_fragment))
  })

  initialization_time <- proc.time()
  if(!Minimize){
    cat("Done.\n")
  }
  #print(fragment_mat)

  # Run kmeans
  # Note: this implementation treats the centres as files, never as PSCOs.
  old_centres <- NULL
  iteration <- 0

  is_converged <- converged(old_centres, centres, epsilon)
  while (!is_converged && iteration < iterations) {
    cat(paste0("Doing iteration #", iteration + 1, "/", iterations, ". "))
    iteration_time <- proc.time()[3]
    old_centres <- centres
    
    partials <- lapply(1:num_fragments, function(i) {
      if(compss_wait_on(fragment_indicator[i])){
        task.partial_sum(bigmatrix_desc = all_points_desc, 
                          start_row = as.integer((i - 1) * points_per_fragment + 1), 
                          end_row = as.integer(i * points_per_fragment), 
                          centres = old_centres)
      }
    })

    centres <- recompute_centres(partials, old_centres, arity)

    iteration <- iteration + 1
    if(DEBUG$kmeans_frag){
      cat("centres:\n")
      print(centres)
    }
    is_converged <- converged(old_centres, centres, epsilon)
    iteration_time <- proc.time()[3] - iteration_time
    cat(paste0("Iteration time: ", round(iteration_time, 3), "\n"))
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
    cat("KMEANS_RCOMPSs_BIGMEMORY,",
        seed, ",",
        numpoints, ",",
        dimensions, ",",
        num_centres, ",",
        num_fragments, ",",
        mode, ",",
        iteration, ",",
        is_converged, ",",
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
  bigmemory::flush(all_points)
  rm(all_points, all_points_desc); gc()
  unlink(c(paste0(bm_base, ".bin"), paste0(bm_base, ".desc")), force = TRUE)
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
rm(list=ls())
gc()