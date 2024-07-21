args <- commandArgs(trailingOnly = TRUE)

use_merge2 <- TRUE

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
  if(!Minimize){
    cat("Done.\n")
  }

  # Define the tasks
  if(!Minimize){
    cat("Defining the tasks ... ")
  }
  task.partial_sum <- task(partial_sum, "tasks_kmeans.R", info_only = FALSE, return_value = TRUE, DEBUG = TRUE)
  task.merge <- task(merge, "tasks_kmeans.R", info_only = FALSE, return_value = TRUE, DEBUG = TRUE)
  task.merge2 <- task(merge2, "tasks_kmeans.R", info_only = FALSE, return_value = TRUE, DEBUG = TRUE)
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

for(replicate in 1){

  start_time <- proc.time()

  # Generate the data
  if(!Minimize){
    cat("Generating data replicate", replicate, "... ")
  }
  fragment_list <- list()
  # Prevent infinite loops
  points_per_fragment <- max(1, numpoints %/% num_fragments)

  points <- generate_points(numpoints, dimensions, mode, seed, num_centres)
  sample_idx <- sample(1:numpoints, numpoints, replace = FALSE)
  for (l in seq(0, numpoints - 1, by = points_per_fragment)) {
    # Note that the seed is different for each fragment.
    # This is done to avoid having repeated data.
    # r <- min(numpoints, l + points_per_fragment)
    # fragment_list[[length(fragment_list) + 1]] <- generate_fragment(r - l, dimensions, mode, seed + l)
    fragment_list[[length(fragment_list) + 1]] <- points[sample_idx[(l + 1):(l + points_per_fragment)], 1:2]
  }
  initialization_time <- proc.time()
  if(!Minimize){
    cat("Done.\n")
  }

  # Run kmeans
  centres <- kmeans_frag(
                         fragment_list = fragment_list,
                         dimensions = dimensions,
                         num_centres = num_centres,
                         iterations = iterations,
                         seed = seed,
                         epsilon = epsilon,
                         arity = arity
                         )

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
    cat("CENTRES:\n")
    print(centres)
    cat("-----------------------------------------\n")
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
      use_RCOMPSs, ",",
      paste(R.version$major, R.version$minor, sep="."), ",",
      Initialization_time, ",",
      Kmeans_time, ",",
      Total_time,
      "\n", sep = ""
      )

}

if(use_RCOMPSs){
  compss_stop()
}

# Plot the data
if(needs_plot){
  # pdf(paste0("kmeans", Sys.time(), ".pdf"))
  pdf("kmeans.pdf")
  plot(points, col = "blue")
  points(centres, col = "red", pch = 8)
  dev.off()
}
