suppressPackageStartupMessages({
  library(mirai)   # lightweight parallelism only
  library(proxy)   # for proxy::dist
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

recompute_centres <- function(merged_partials, old_centres) {
  dimension <- ncol(old_centres)
  centres <- old_centres

  cl0 <- which(merged_partials[, dimension + 1] == 0) # empty clusters
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
    cat("Usage: Rscript kmeans_mirai.R [options]\n")
    cat("Options:\n")
    cat("  -s, --seed <seed>                RNG seed\n")
    cat("  -n, --numpoints <numpoints>      Number of points\n")
    cat("  -d, --dimensions <dimensions>    Number of dimensions\n")
    cat("  -c, --num_centres <num_centres>  Number of centers\n")
    cat("  -f, --fragments <fragments>      Number of fragments\n")
    cat("  -m, --mode <mode>                Data mode (uniform|normal)\n")
    cat("  -i, --iterations <iterations>    Max iterations\n")
    cat("  -e, --epsilon <epsilon>          Convergence epsilon\n")
    cat("  -a, --arity <arity>              Reduction arity\n")
    cat("  -p, --plot <needs_plot>          Unused here\n")
    cat("      --plan <name>                Compatibility only\n")
    cat("      --workers <N>                Number of mirai daemons\n")
    cat("  -M, --Minimize                   Minimize printout\n")
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
  cat(sprintf("  plan (compat): %s\n", params$plan_name))
  cat(sprintf("  workers: %s\n", ifelse(is.na(params$workers), "auto", as.character(params$workers))))
}

# ----------------------------
# Main script
# ----------------------------

args <- commandArgs(trailingOnly = TRUE)
Minimize <- any(args %in% c("-M", "--Minimize"))
params <- parse_arguments(Minimize)
if(!Minimize) print_parameters(params)
attach(params)

# Configure mirai daemons (no nanonext)
if (!Minimize) cat("Configuring mirai daemons ... ")
n_workers <- if (is.na(workers)) {
  max(1L, parallel::detectCores(logical = TRUE) - 1L)
} else {
  workers
}
sequential_mode <- identical(plan_name, "sequential") || n_workers <= 1L
if (sequential_mode) {
  daemons(0L)
  if (!Minimize) cat("sequential (local tasks).\n")
} else {
  daemons(n_workers)
  if (!Minimize) cat(sprintf("Started %d daemons.\n", n_workers))
}

set.seed(seed)
for(replicate in 1:10){
  start_time <- proc.time()

  if(!Minimize) cat("Launching background data generation...\n")
  points_per_fragment <- numpoints %/% num_fragments
  true_centres <- matrix(runif(num_centres * dimensions), nrow = num_centres, ncol = dimensions)

  # Launch mirai tasks to generate fragments
  fragment_mirai <- vector("list", num_fragments)
  for (f in 1:num_fragments) {
    frag_seed <- seed + 10000L + f

    fragment_mirai[[f]] <- mirai(
                                 .expr = {
                                   set.seed(frag_seed)
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
                                 },
                                 .args = list(
                                              centres = true_centres,
                                              n = points_per_fragment,
                                              mode = mode,
                                              frag_seed = frag_seed
                                              ),
                                 .compute = if (sequential_mode) "local" else NULL
    )
  }


  # Initialize centres and loop variables
  centres <- matrix(runif(num_centres * dimensions), nrow = num_centres, ncol = dimensions)
  old_centres <- NULL
  iteration <- 0

  initialization_time <- proc.time()
  if(!Minimize) cat("Data generation complete.\n")

  # K-means iterations
  while (!converged(old_centres, centres, epsilon, iteration, iterations)) {
    cat(paste0("Doing iteration #", iteration + 1, "/", iterations, ". "))
    iteration_time <- proc.time()[3]
    old_centres <- centres

    # Create mirai tasks for partial sums
    partials_mirai <- vector("list", num_fragments)
    for (f in 1:num_fragments) {
      frag <- collect_mirai(fragment_mirai[[f]])
      partials_mirai[[f]] <- mirai(
                                   .expr = {
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
                                   },
                                   .args = list(
                                                fragment = frag,
                                                centres = old_centres
                                                ),
                                   .compute = if (sequential_mode) "local" else NULL
      )
    }

    # Wait and collect partials
    partials_mirai <- collect_mirai(partials_mirai)

    # Merge and recompute centres
    merged_partials <- do.call(merge, partials_mirai)
    centres <- recompute_centres(merged_partials, old_centres)

    iteration <- iteration + 1
    iteration_time <- proc.time()[3] - iteration_time
    cat(paste0("Iteration time: ", round(iteration_time, 3), "\n"))
  }

  kmeans_time <- proc.time()

  # Results and Timing
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

  type <- paste0("mirai_", if (sequential_mode) "sequential" else "daemons")
  if(Minimize){
    cat("KMEANS_MIRAI,",
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

# Shut down daemons if started
if (!sequential_mode) daemons(0L)
