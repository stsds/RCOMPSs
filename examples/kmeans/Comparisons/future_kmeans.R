# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# Converted to future-based parallelism (replacing RCOMPSs).

# @file kmeans_future.R
# @brief Main application of K-means clustering with future parallelization
# @version 1.1 (future)
# @author (original) Xiran Zhang; (conversion) Assistant
# @date 2025-08-24

library(future)
library(future.apply)
library(proxy)  # for proxy::dist

DEBUG <- list(
              partial_sum = FALSE,
              merge = FALSE,
              converged = FALSE,
              recompute_centres = FALSE,
              kmeans_frag = FALSE
)

# ----------------------------
# Core computation utilities
# ----------------------------

fill_fragment <- function(params_fill_fragment){
  centres <- params_fill_fragment[[1]]
  n <- params_fill_fragment[[2]]
  mode <- params_fill_fragment[[3]]

  ncluster <- nrow(centres)
  dim <- ncol(centres)

  rand <- list(
               "normal" = function(k) rnorm(k, mean = 0, sd = 0.05),
               "uniform" = function(k) runif(k, 0, 0.1)
  )

  frag <- matrix(rand[[mode]](n * dim), nrow = n, ncol = dim)
  group_ind <- sample(1:ncluster, n, replace = TRUE)
  frag <- frag + centres[group_ind, ]
  return(frag)
}

partial_sum <- function(fragment, centres) {
  ncl <- nrow(centres)
  if(ncol(fragment) != ncol(centres)) {
    stop("fragment and centres must have the same number of columns\nNow fragment has <", ncol(fragment), "> columns and centres has <", ncol(centres), "> columns\n", sep = "")
  } else {
    dimension <- ncol(fragment)
  }
  if(DEBUG$partial_sum) {
    cat("Doing partial sum\n")
    cat("nrow(centres) =", nrow(centres), "\n")
    cat(paste0("dimension = ", dimension, "\n"))
  }

  partials <- matrix(NA_real_, nrow = ncl, ncol = dimension + 1)
  close_centres <- apply(proxy::dist(fragment, centres, method = "euclidean"), 1, which.min)

  for (center_idx in 1:ncl) {
    indices <- which(close_centres == center_idx)
    if(length(indices) == 0){
      partials[center_idx,] <- 0
    }else if(length(indices) == 1){
      partials[center_idx, 1:dimension] <- fragment[indices, ]
      partials[center_idx, dimension + 1] <- 1
    }else{
      partials[center_idx, 1:dimension] <- colSums(fragment[indices, , drop = FALSE])
      partials[center_idx, dimension + 1] <- length(indices)
    }
  }
  return(partials)
}

merge <- function(...){
  input <- list(...)
  input_len <- length(input)
  if(DEBUG$merge) {
    cat("Doing merge\n")
    for(i in 1:input_len){
      cat("Input", i, "\n")
      print(input[[i]])
    }
  }
  if(input_len == 1){
    return(input[[1]])
  }else if(input_len >= 2){
    accum <- input[[1]]
    for(i in 2:input_len){
      accum <- accum + input[[i]]
    }
    if(DEBUG$merge) {
      cat("accum\n")
      print(accum)
    }
    return(accum)
  }else{
    stop("Wrong input in `merge`!\n")
  }
}

converged <- function(old_centres, centres, epsilon, iteration, max_iter) {
  if(DEBUG$converged) cat("Doing converged\n")
  if(is.null(old_centres)) return(FALSE)
  dist <- sum(rowSums((centres - old_centres)^2))
  if(dist < epsilon^2){
    cat("Converged!\n")
    End <- TRUE
  }else if(iteration >= max_iter){
    cat("Max iteration reached!\n")
    End <- TRUE
  }else{
    End <- FALSE
  }
  return(End)
}

# Parallel tree-reduction using future
recompute_centres <- function(partials, old_centres, arity, future_reduction_plan = NULL) {
  if(DEBUG$recompute_centres){
    cat("\n\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
    cat("Doing recompute centres\n")
  }
  dimension <- ncol(old_centres)
  centres <- old_centres

  # Optional: temporarily use a sub-plan for reduction if provided
  #if (!is.null(future_reduction_plan)) {
  #  oplan <- future::plan()
  #  on.exit(future::plan(oplan), add = TRUE)
  #  future::plan(future_reduction_plan)
  #}

  partials <- do.call(merge, partials)

  # For empty clusters, assign random new mean; else average
  cl0 <- which(partials[, dimension + 1] == 0)
  if(length(cl0) > 0){
    centres[cl0,] <- matrix(runif(length(cl0) * dimension), nrow = length(cl0), ncol = dimension)
    if (length(setdiff(seq_len(nrow(partials)), cl0)) > 0) {
      centres[-cl0,] <- partials[-cl0, 1:dimension, drop = FALSE] / partials[-cl0, dimension + 1]
    }
  }else{
    centres <- partials[,1:dimension, drop = FALSE] / partials[,dimension + 1]
  }
  return(centres)
}

# ----------------------------
# Argument parsing
# ----------------------------

parse_arguments <- function(Minimize) {
  if(!Minimize){
    cat("Starting parse_arguments\n")
  }

  args <- commandArgs(trailingOnly = TRUE)

  seed <- 1
  numpoints <- 100
  dimensions <- 2
  num_centres <- 5
  fragments <- 10
  mode <- "uniform"
  iterations <- 20
  epsilon <- 1e-9
  arity <- 5

  # Parallel plan for future
  plan_name <- "multisession"   # default that works on all OSes
  workers <- NA_integer_        # NA -> future decides
  is.asking_for_help <- FALSE
  needs_plot <- TRUE

  if(length(args) >= 1){
    for (i in 1:length(args)) {
      if (args[i] == "-s" || args[i] == "--seed") {
        seed <- as.integer(args[i + 1])
      } else if (args[i] == "-n" || args[i] == "--numpoints") {
        numpoints <- as.integer(args[i + 1])
      } else if (args[i] == "-d" || args[i] == "--dimensions") {
        dimensions <- as.integer(args[i + 1])
      } else if (args[i] == "-c" || args[i] == "--num_centres") {
        num_centres <- as.integer(args[i + 1])
      } else if (args[i] == "-f" || args[i] == "--fragments") {
        fragments <- as.integer(args[i + 1])
      } else if (args[i] == "-m" || args[i] == "--mode") {
        mode <- args[i + 1]
      } else if (args[i] == "-i" || args[i] == "--iterations") {
        iterations <- as.integer(args[i + 1])
      } else if (args[i] == "-e" || args[i] == "--epsilon") {
        epsilon <- as.double(args[i + 1])
      } else if (args[i] == "-a" || args[i] == "--arity") {
        arity <- as.integer(args[i + 1])
      } else if (args[i] == "-p" || args[i] == "--plot") {
        needs_plot <- as.logical(args[i + 1])
      } else if (args[i] == "-h" || args[i] == "--help") {
        is.asking_for_help <- TRUE
      } else if (args[i] == "--plan") {
        plan_name <- args[i + 1]
      } else if (args[i] == "--workers") {
        workers <- as.integer(args[i + 1])
      }
    }
  }

  if(is.asking_for_help){
    cat("Usage: Rscript kmeans_future.R [options]\n")
    cat("Options:\n")
    cat("  -s, --seed <seed>                Seed for random number generator\n")
    cat("  -n, --numpoints <numpoints>      Number of points\n")
    cat("  -d, --dimensions <dimensions>    Number of dimensions\n")
    cat("  -c, --num_centres <num_centres>  Number of centers\n")
    cat("  -f, --fragments <fragments>      Number of fragments\n")
    cat("  -m, --mode <mode>                Mode for generating points\n")
    cat("  -i, --iterations <iterations>    Maximum number of iterations\n")
    cat("  -e, --epsilon <epsilon>          Epsilon (convergence distance)\n")
    cat("  -a, --arity <arity>              Reduction arity (batch size in tree reduction)\n")
    cat("  -p, --plot <needs_plot>          Boolean: Plot? (not used here)\n")
    cat("      --plan <name>                future plan: sequential|multisession|multicore|cluster\n")
    cat("      --workers <N>                Number of workers for the plan\n")
    cat("  -M, --Minimize                   Minimize printout\n")
    cat("  -h, --help                       Show this help message\n")
    q(status = 0)
  }

  if(numpoints %% fragments){
    stop("Number of fragment is not a factor of number of points!\n")
  }

  list(
       seed = seed,
       numpoints = numpoints,
       dimensions = dimensions,
       num_centres = num_centres,
       num_fragments = fragments,
       mode = mode,
       iterations = iterations,
       epsilon = epsilon,
       arity = arity,
       needs_plot = needs_plot,
       plan_name = plan_name,
       workers = workers
  )
}

print_parameters <- function(params) {
  cat("Parameters:\n")
  cat(sprintf("  Seed: %d\n", params$seed))
  cat(sprintf("  Number of points: %d\n", params$numpoints))
  cat(sprintf("  Dimensions: %d\n", params$dimensions))
  cat(sprintf("  Number of centers: %d\n", params$num_centres))
  cat(sprintf("  Number of fragments: %d\n", params$num_fragments))
  cat(sprintf("  Mode: %s\n", params$mode))
  cat(sprintf("  Iterations: %d\n", params$iterations))
  cat(sprintf("  Epsilon: %.e\n", params$epsilon))
  cat(sprintf("  Arity: %d\n", params$arity))
  cat("  needs_plot:", params$needs_plot, "\n")
  cat(sprintf("  future plan: %s\n", params$plan_name))
  cat(sprintf("  workers: %s\n", ifelse(is.na(params$workers), "auto", as.character(params$workers))))
}

# ----------------------------
# Main script
# ----------------------------

flush.console()
Sys.sleep(1)

args <- commandArgs(trailingOnly = TRUE)
Minimize <- FALSE
if(length(args) >= 1){
  for (i in 1:length(args)) {
    if (args[i] == "-M" || args[i] == "--Minimize") {
      Minimize <- TRUE
    }
  }
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

# Configure future plan
# Map step uses the global plan; you may choose a different plan for reduction if desired.
if (!Minimize) cat("Configuring future plan ... ")
options(future.globals.maxSize = Inf)
plan_obj <- switch(plan_name,
                   "sequential"   = plan(sequential),
                   "multisession" = if (is.na(workers)) plan(multisession) else plan(multisession, workers = workers),
                   "multicore"    = if (is.na(workers)) plan(multicore) else plan(multicore, workers = workers),
                   "cluster"      = {
                     if (is.na(workers)) workers <- parallel::detectCores(logical = TRUE)
                     cl <- parallel::makeCluster(workers)
                     on.exit(try(parallel::stopCluster(cl), silent = TRUE), add = TRUE)
                     plan(cluster, workers = cl)
                   },
                   { warning("Unknown plan name; defaulting to multisession."); plan(multisession) }
)
if (!Minimize) cat("Done.\n")

# You can optionally set a different plan for reduction; here we keep NULL to reuse the global plan:
reduction_plan <- NULL

set.seed(seed)
for(replicate in 1:1){
  start_time <- proc.time()

  # Generate the data
  if(!Minimize){
    cat("Generating data replicate", replicate, "... ")
  }
  points_per_fragment <- max(1, numpoints %/% num_fragments)
  true_centres <- matrix(runif(num_centres * dimensions),
                         nrow = num_centres, ncol = dimensions)

  # Generate fragments (this part could also be parallelized; we keep it sequential to preserve determinism)
  fragment_list <- vector("list", num_fragments)
  for (f in 1:num_fragments) {
    fragment_list[[f]] <- future({
      params_fill_fragment <- list(true_centres, points_per_fragment, mode)
      fill_fragment(params_fill_fragment)
    }, seed = seed)
  }

  initialization_time <- proc.time()
  if(!Minimize){
    cat("Done.\n")
  }

  # Run kmeans

  # kmeans_frag
  # Initialize centres
  centres <- matrix(runif(num_centres * dimensions), nrow = num_centres, ncol = dimensions)
  if(DEBUG$kmeans_frag){
    cat("Initialized centres:\n")
    print(centres)
  }

  old_centres <- NULL
  iteration <- 0
  num_frag <- length(fragment_list)

  while (!converged(old_centres, centres, epsilon, iteration, iterations)) {
    cat(paste0("Doing iteration #", iteration + 1, "/", iterations, ". "))
    iteration_time <- proc.time()[3]
    old_centres <- centres
    partials <- list()

    # Map step: partial sums per fragment, in parallels
    if(DEBUG$kmeans_frag){
      cat("\npartial sums per fragment.\n")
    }
    for(i in 1:num_frag){
      if("Future" %in% class(fragment_list[[i]])){
        fragment_list[[i]] <- value(fragment_list[[i]])
      }
      partials[[i]] <- future({
        partial_sum(fragment = fragment_list[[i]], old_centres)
      })
    }
    if(DEBUG$kmeans_frag){
      cat("getting values per fragment.\n")
    }
    partials <- value(partials)
    #for(i in 1:length(partials)){
    #  partials[[i]] <- value(partials[[i]])
    #}
    if(DEBUG$kmeans_frag){
      cat("recompute_centres\n")
    }
    centres <- recompute_centres(partials, old_centres, arity, future_reduction_plan = reduction_plan)

    iteration <- iteration + 1
    if(DEBUG$kmeans_frag){
      cat("centres:\n")
      print(centres)
    }
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
    ind_centres <- sort(centres[,1], index.return = TRUE)$ix
    ind_true_centres <- sort(true_centres[,1], index.return = TRUE)$ix
    cat("CENTRES\n")
    print(centres[ind_centres, , drop = FALSE])
    cat("TRUE CENTRES\n")
    print(true_centres[ind_true_centres, , drop = FALSE])
    cat("-----------------------------------------\n")
  }

  type <- paste0("future_", plan_name)
  if(Minimize){
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
}
