# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

# @file functions_kmeans.R
# @brief This file contains the functions for the K-means clustering application
# @version 1.0
# @author Xiran Zhang
# @date 2025-04-28

converged <- function(old_centres, centres, epsilon, iteration, max_iter) {
  if(DEBUG$converged) {
    cat("Doing converged\n")
  }
  if(is.null(old_centres)) {
    return(FALSE)
  }
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

recompute_centres <- function(partials, old_centres, arity) {
  if(DEBUG$recompute_centres){
    cat("\n\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
    cat("Doing recompute centres\n")
    cat("partials:\n")
    print(partials)
    cat("old_centres:\n")
    print(old_centres)
    cat("arity:\n")
    print(arity)
  }
  dimension <- ncol(old_centres)
  centres <- old_centres
  if(DEBUG$recompute_centres){
    cat("length(partials) =", length(partials), "\n")
    cat("arity =", arity, "\n\n")
  }

  while(length(partials) > arity) {
    if(DEBUG$recompute_centres >= 2){
      cat("\npartials in recompute_centres\n")
      print(partials)
    }
    if(DEBUG$recompute_centres >= 1){
      cat("length(partials) > arity\n")
    }
    partials_subset <- partials[1:arity]
    if(DEBUG$recompute_centres >= 1){
      cat("partials_subset\n")
      print(partials_subset)
    }
    partials <- partials[(arity + 1):length(partials)]
    if(use_RCOMPSs){
      partials[[length(partials) + 1]] <- do.call(task.merge, partials_subset)
    }else{
      partials[[length(partials) + 1]] <- do.call(merge, partials_subset)
    }
  }
  if(DEBUG$recompute_centres >= 1){
    cat("length(partials) <= arity\n")
  }
  if(use_RCOMPSs){
    partials <- do.call(task.merge, partials)
    partials <- compss_wait_on(partials)
  }else{
    partials <- do.call(merge, partials)
  }
  # For empty clusters, we give a random new mean
  cl0 <- which(partials[,dimension + 1] == 0)
  if(length(cl0) > 0){
    centres[cl0,] <- matrix(runif(length(cl0) * dimension), nrow = length(cl0), ncol = dimension)
    centres[-cl0,] <- partials[-cl0, 1:dimension] / partials[-cl0, dimension + 1]
  }else{
  centres <- partials[,1:dimension] / partials[,dimension + 1]
  }
  if(DEBUG$recompute_centres >= 2){
    cat("\npartials in recompute_centres after merge\n")
    print(partials)
    cat("dimension =", dimension, "\n")
    cat("\ncentres\n")
    print(centres)
  }
  return(centres)
}


#' A fragment-based K-Means algorithm.
#'
#' Given a set of fragments, the desired number of clusters and the
#' maximum number of iterations, compute the optimal centres and the
#' index of the centre for each point.
#'
#' @param fragments Number of fragments
#' @param dimensions Number of dimensions
#' @param num_centres Number of centres
#' @param iterations Maximum number of iterations
#' @param seed Random seed
#' @param epsilon Epsilon (convergence distance)
#' @param arity Reduction arity
#' @return Final centres
kmeans_frag <- function(fragment_list, num_centres = 10, iterations = 20, epsilon = 1e-9, arity = 50) {
  # Centres is usually a very small matrix, so it is affordable to have it in
  # the master.
  # TODO: The centres should be generated in a way that at least there is one point in the fragment that is close to the centre.
  centres <- matrix(runif(num_centres * dimensions), nrow = num_centres, ncol = dimensions)
  if(DEBUG$kmeans_frag){
        cat("Initialized centres:\n")
        print(centres)
      }

  # Note: this implementation treats the centres as files, never as PSCOs.
  old_centres <- NULL
  iteration <- 0

  # Necessary parameters
  dimensions <- ncol(fragment_list[[1]]) - 1                         # dimensions of the data
  num_frag <- length(fragment_list)              # number of fragments in total

  while (!converged(old_centres, centres, epsilon, iteration, iterations)) {
    cat(paste0("Doing iteration #", iteration + 1, "/", iterations, ". "))
    iteration_time <- proc.time()[3]
    old_centres <- centres
    if(use_RCOMPSs && use_merge2){
      partials_accum <- matrix(0, nrow = nrow(centres), ncol = dimensions + 1)
      for(i in 1:num_frag){
        partials <- task.partial_sum(fragment = fragment_list[[i]], old_centres)
        partials_accum <- task.merge2(partials_accum, partials)
      }
      partials_accum <- compss_wait_on(partials_accum)
      if(DEBUG$kmeans_frag){
        cat("use_RCOMPSs = TRUE; use_merge2 = TRUE\n")
        cat("partials_accum:\n")
        print(partials_accum)
      }
      centres <- partials_accum[,1:dimensions] / partials_accum[,dimensions + 1]
    }else{
      partials <- list()
      if(use_RCOMPSs){
        if(DEBUG$kmeans_frag){
          cat("use_RCOMPSs = TRUE; use_merge2 = FALSE\n")
        }
        for(i in 1:num_frag){
          partials[[i]] <- task.partial_sum(fragment = fragment_list[[i]], old_centres)
        }
      }else{
        for(i in 1:num_frag){
          partials[[i]] <- partial_sum(fragment = fragment_list[[i]], old_centres)
        }
        if(DEBUG$kmeans_frag){
          cat("use_RCOMPSs = FALSE; use_merge2 = FALSE\n")
          cat("partials in kmeans_frag:\n")
          print(partials)
        }
      }
      centres <- recompute_centres(partials, old_centres, arity)
    }
    iteration <- iteration + 1
    if(DEBUG$kmeans_frag){
      cat("centres:\n")
      print(centres)
    }
    iteration_time <- proc.time()[3] - iteration_time
    cat(paste0("Iteration time: ", round(iteration_time, 3), "\n"))
  }
  return(centres)
}

parse_arguments <- function(Minimize) {

  if(!Minimize){
    cat("Starting parse_arguments\n")
  }

  args <- commandArgs(trailingOnly = TRUE)

  # Define default values
  # Note that if `num_fragments` is not a factor of `numpoints`, the last fragment may give NA due to lack of points.
  seed <- 1
  numpoints <- 100
  dimensions <- 2
  num_centres <- 5
  fragments <- 10 
  mode <- "uniform"
  iterations <- 20
  epsilon <- 1e-9
  arity <- 5

  # Execution using RCOMPSs
  use_RCOMPSs <- FALSE

  # Execution using default R function
  use_R_default <- FALSE

  # asking for help
  is.asking_for_help <- FALSE

  # plot?
  needs_plot <- TRUE

  # Parse arguments
  if(length(args) >= 1){
    for (i in 1:length(args)) {
      if (args[i] == "-s") {
        seed <- as.integer(args[i + 1])
      } else if (args[i] == "--seed") {
        seed <- as.integer(args[i + 1])
      } else if (args[i] == "-n") {
        numpoints <- as.integer(args[i + 1])
      } else if (args[i] == "--numpoints") {
        numpoints <- as.integer(args[i + 1])
      } else if (args[i] == "-d") {
        dimensions <- as.integer(args[i + 1])
      } else if (args[i] == "--dimensions") {
        dimensions <- as.integer(args[i + 1])
      } else if (args[i] == "-c") {
        num_centres <- as.integer(args[i + 1])
      } else if (args[i] == "--num_centres") {
        num_centres <- as.integer(args[i + 1])
      } else if (args[i] == "-f") {
        fragments <- as.integer(args[i + 1])
      } else if (args[i] == "--fragments") {
        fragments <- as.integer(args[i + 1])
      } else if (args[i] == "-m") {
        mode <- args[i + 1]
      } else if (args[i] == "--mode") {
        mode <- args[i + 1]
      } else if (args[i] == "-i") {
        iterations <- as.integer(args[i + 1])
      } else if (args[i] == "--iterations") {
        iterations <- as.integer(args[i + 1])
      } else if (args[i] == "-e") {
        epsilon <- as.double(args[i + 1])
      } else if (args[i] == "--epsilon") {
        epsilon <- as.double(args[i + 1])
      } else if (args[i] == "-a") {
        arity <- as.integer(args[i + 1])
      } else if (args[i] == "--arity") {
        arity <- as.integer(args[i + 1])
      } else if (args[i] == "-p") {
        needs_plot <- as.logical(args[i + 1])
      } else if (args[i] == "--plot") {
        needs_plot <- as.logical(args[i + 1])
      } else if (args[i] == "-C") {
        use_RCOMPSs <- TRUE
      } else if (args[i] == "--RCOMPSs") {
        use_RCOMPSs <- TRUE
      } else if (args[i] == "-R") {
        use_R_default <- TRUE
      } else if (args[i] == "--R-default") {
        use_R_default <- FALSE
      } else if (args[i] == "-h") {
        is.asking_for_help <- TRUE
      } else if (args[i] == "--help") {
        is.asking_for_help <- TRUE
      }
    }
  }

  if(is.asking_for_help){
    cat("Usage: Rscript kmeans.R [options]\n")
    cat("Options:\n")
    cat("  -s, --seed <seed>                Seed for random number generator\n")
    cat("  -n, --numpoints <numpoints>      Number of points\n")
    cat("  -d, --dimensions <dimensions>    Number of dimensions\n")
    cat("  -c, --num_centres <num_centres>  Number of centers\n")
    cat("  -f, --fragments <fragments>      Number of fragments\n")
    cat("  -m, --mode <mode>                Mode for generating points\n")
    cat("  -i, --iterations <iterations>    Maximum number of iterations\n")
    cat("  -e, --epsilon <epsilon>          Epsilon (convergence distance)\n")
    cat("  -a, --arity <arity>              Reduction arity\n")
    cat("  -p, --plot <needs_plot>          Boolean: Plot?\n")
    cat("  -C, --RCOMPSs <use_RCOMPSs>      Boolean: Use RCOMPSs parallelization?\n")
    cat("  -M, --Minimize <Minimize>        Boolean: Minimize printout?\n")
    cat("  -h, --help                       Show this help message\n")
    q(status = 0)
  }

  if(numpoints %% fragments){
    stop("Number of fragment is not a factor of number of points!\n")
  }

  if(use_RCOMPSs && use_R_default){
    stop("Default R function `kmeans` cannot run with RCOMPSs\n")
  }

  return(list(
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
              use_RCOMPSs = use_RCOMPSs,
              use_R_default = use_R_default
              ))
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
  cat("  use_RCOMPSs:", params$use_RCOMPSs, "\n")
  cat("  use_R_default:", params$use_R_default, "\n")
}
