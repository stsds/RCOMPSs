suppressPackageStartupMessages({
  library(future)
  library(proxy)  # for proxy::dist
  library(bigmemory)
})

DEBUG <- list(
  partial_sum = FALSE,
  merge = FALSE,
  converged = FALSE,
  recompute_centres = FALSE,
  kmeans_frag = FALSE
)

# ------------------------------------
# Core Computation Utilities
# ------------------------------------

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
  dimension <- ncol(fragment)
  
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
  if(length(input) == 1){
    return(input[[1]])
  } else {
    return(Reduce(`+`, input))
  }
}

converged <- function(old_centres, centres, epsilon, iteration, max_iter) {
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

# --------------------------------------------
# <<< OPTIMIZED ASYNCHRONOUS FUNCTIONS >>>
# --------------------------------------------

#' Asynchronous Tree Reduction for Merging Partials
#'
#' Takes a list of futures and returns a single future that represents the
#' final merged result of a reduction tree. This function is non-blocking.
#'
#' @param futures_list A list of future objects for the partial sums.
#' @param arity The branching factor of the reduction tree.
#' @return A single future object that will resolve to the final merged matrix.
merge_partials_async <- function(futures_list, arity) {
  level <- futures_list
  while (length(level) > 1) {
    groups <- split(level, ceiling(seq_along(level) / arity))
    level <- lapply(groups, function(group_of_futures) {
      future({
        do.call(merge, value(group_of_futures))
      }, seed = TRUE)
    })
  }
  return(level[[1]])
}

#' Simplified Recompute Centres Function
#'
#' Takes the *resolved* merged partials matrix and computes the new centres.
#' This is the final, serial step after the asynchronous reduction is complete.
#'
#' @param merged_partials The matrix result from the merge reduction.
#' @param old_centres The matrix of the previous iteration's centres.
#' @return A matrix containing the new centres.
recompute_centres <- function(merged_partials, old_centres) {
  dimension <- ncol(old_centres)
  centres <- old_centres
  
  cl0 <- which(merged_partials[, dimension + 1] == 0) # Find empty clusters
  if (length(cl0) > 0) {
    centres[cl0, ] <- matrix(runif(length(cl0) * dimension), nrow = length(cl0), ncol = dimension)
    non_empty_clusters <- setdiff(seq_len(nrow(merged_partials)), cl0)
    if (length(non_empty_clusters) > 0) {
      centres[non_empty_clusters, ] <- merged_partials[non_empty_clusters, 1:dimension, drop = FALSE] / merged_partials[non_empty_clusters, dimension + 1]
    }
  } else {
    centres <- merged_partials[, 1:dimension, drop = FALSE] / merged_partials[, dimension + 1]
  }
  return(centres)
}


# ----------------------------
# Argument parsing & Setup
# (No changes needed here)
# ----------------------------

parse_arguments <- function(Minimize) {
  if(!Minimize) cat("Starting parse_arguments\n")
  args <- commandArgs(trailingOnly = TRUE)
  
  # Default values
  seed <- 1; numpoints <- 100; dimensions <- 2; num_centres <- 5
  fragments <- 10; mode <- "uniform"; iterations <- 20
  epsilon <- 1e-9; arity <- 5; plan_name <- "multisession"
  workers <- NA_integer_; is.asking_for_help <- FALSE; needs_plot <- TRUE
  
  if(length(args) >= 1){
    for (i in 1:length(args)) {
      if (args[i] %in% c("-s", "--seed")) seed <- as.integer(args[i + 1])
      else if (args[i] %in% c("-n", "--numpoints")) numpoints <- as.integer(args[i + 1])
      else if (args[i] %in% c("-d", "--dimensions")) dimensions <- as.integer(args[i + 1])
      else if (args[i] %in% c("-c", "--num_centres")) num_centres <- as.integer(args[i + 1])
      else if (args[i] %in% c("-f", "--fragments")) fragments <- as.integer(args[i + 1])
      else if (args[i] %in% c("-m", "--mode")) mode <- args[i + 1]
      else if (args[i] %in% c("-i", "--iterations")) iterations <- as.integer(args[i + 1])
      else if (args[i] %in% c("-e", "--epsilon")) epsilon <- as.double(args[i + 1])
      else if (args[i] %in% c("-a", "--arity")) arity <- as.integer(args[i + 1])
      else if (args[i] %in% c("-p", "--plot")) needs_plot <- as.logical(args[i + 1])
      else if (args[i] %in% c("-h", "--help")) is.asking_for_help <- TRUE
      else if (args[i] == "--plan") plan_name <- args[i + 1]
      else if (args[i] == "--workers") workers <- as.integer(args[i + 1])
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
  
  if(numpoints %% fragments) stop("Number of fragments must be a factor of number of points!\n")
  
  list(seed=seed, numpoints=numpoints, dimensions=dimensions, num_centres=num_centres,
       num_fragments=fragments, mode=mode, iterations=iterations, epsilon=epsilon,
       arity=arity, needs_plot=needs_plot, plan_name=plan_name, workers=workers)
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

# --- Argument Parsing and Setup ---
args <- commandArgs(trailingOnly = TRUE)
Minimize <- any(args %in% c("-M", "--Minimize"))
params <- parse_arguments(Minimize)
if(!Minimize) print_parameters(params)
attach(params)

# --- Configure Future Plan ---
if (!Minimize) cat("Configuring future plan ... ")
options(future.globals.maxSize = Inf)
plan_obj <- switch(plan_name,
                   "sequential"   = plan(sequential),
                   "multisession" = if (is.na(workers)) plan(multisession) else plan(multisession, workers = workers),
                   "multicore"    = if (is.na(workers)) plan(multicore) else plan(multicore, workers = workers),
                   { warning("Unknown plan name; defaulting to multisession."); plan(multisession) }
)
if (!Minimize) cat("Done.\n")

# --- Main K-means Execution ---
set.seed(seed)
for(replicate in 1:10){
  start_time <- proc.time()
  
  # --- Pre-allocate the Shared Memory Matrix ---
  if(!Minimize) cat("Creating shared big.matrix for data generation...\n")
  all_points <- big.matrix(nrow = numpoints, ncol = dimensions, type = "double")
  all_points_desc <- describe(all_points) # A descriptor to find the matrix
  
  # --- Generate Data Fragments in Parallel ---
  if(!Minimize) cat("Launching background data generation...\n")
  points_per_fragment <- numpoints %/% num_fragments
  true_centres <- matrix(runif(num_centres * dimensions), nrow = num_centres, ncol = dimensions)
  
  fragment_futures <- vector("list", num_fragments)
  for (f in 1:num_fragments) {
    fragment_futures[[f]] <- future({
      # Each worker attaches to the shared matrix
      points_mat <- attach.big.matrix(all_points_desc)
      # Generate the data fragment
      fragment_data <- fill_fragment(list(true_centres, points_per_fragment, mode))
      start_row <- ((f - 1) * points_per_fragment) + 1
      end_row <- f * points_per_fragment
      # Write the result directly to shared memory (side effect)
      points_mat[start_row:end_row, ] <- fragment_data
      return(NULL) # Return nothing to avoid data transfer
    }, seed = TRUE)
  }
  # --- Initialize Centres and Loop Variables ---
  centres <- matrix(runif(num_centres * dimensions), nrow = num_centres, ncol = dimensions)
  old_centres <- NULL
  iteration <- 0
  
  # Resolve all fragments ONCE before the loop starts.
  fragment_list <- value(fragment_futures)

  initialization_time <- proc.time()
  if(!Minimize) cat("Done.\n")
  
  # ------------------------------------------------------------------
  # <<< OPTIMIZED K-MEANS ITERATION LOOP >>>
  # ------------------------------------------------------------------
  while (!converged(old_centres, centres, epsilon, iteration, iterations)) {
    cat(paste0("Doing iteration #", iteration + 1, "/", iterations, ". "))
    iteration_time <- proc.time()[3]
    old_centres <- centres
    
    # 1. MAP: Create futures for all partial sums.
    #    This is non-blocking. `partials_futures` is a list of promises.
    partials_futures <- vector("list", num_fragments)
    for (f in 1:num_fragments) {
      partials_futures[[f]] <- future({
        points_mat <- attach.big.matrix(all_points_desc)
        start_row <- ((f - 1) * points_per_fragment) + 1
        end_row <- f * points_per_fragment
        fragment_data <- points_mat[start_row:end_row, ]
        partial_sum(fragment = fragment_data, old_centres)
        }, seed = TRUE)
    }
    
    partials_list <- value(partials_futures)

    partials_list <- do.call(merge, partials_list)
    centres <- recompute_centres(partials_list, old_centres)
    
    iteration <- iteration + 1
    iteration_time <- proc.time()[3] - iteration_time
    cat(paste0("Iteration time: ", round(iteration_time, 3), "\n"))
  }
  
  kmeans_time <- proc.time()
  
  # --- Results and Timing ---
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
    cat("KMEANS_FUTUREBIGMEMORY,",
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
