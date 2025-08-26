suppressPackageStartupMessages({
  require(parallel)
  require(proxy)  # for proxy::dist
})

DEBUG <- list(
  partial_sum = FALSE,
  merge = FALSE,
  converged = FALSE,
  recompute_centres = FALSE,
  kmeans_frag = FALSE
)

# -------- Core tasks --------

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
  frag
}

partial_sum <- function(fragment, centres) {
  ncl <- nrow(centres)
  stopifnot(ncol(fragment) == ncol(centres))
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
  partials
}

merge <- function(...){
  input <- list(...)
  if (length(input) == 0L) stop("merge requires at least one argument")
  if (length(input) == 1L) return(input[[1]])
  accum <- input[[1]]
  for (i in 2:length(input)) accum <- accum + input[[i]]
  accum
}

converged <- function(old_centres, centres, epsilon, iteration, max_iter) {
  if (is.null(old_centres)) return(FALSE)
  dist <- sum(rowSums((centres - old_centres)^2))
  if (dist < epsilon^2) {
    cat("Converged!\n"); TRUE
  } else if (iteration >= max_iter) {
    cat("Max iteration reached!\n"); TRUE
  } else {
    FALSE
  }
}

# -------- Helpers (force mclapply) --------

cores_from_arg <- function(workers) {
  if (is.null(workers) || is.na(workers)) {
    max(1L, parallel::detectCores(logical = TRUE))
  } else {
    as.integer(workers)
  }
}

# -------- Reduction with mclapply --------

recompute_centres <- function(partials, old_centres, arity, workers = NULL) {
  dimension <- ncol(old_centres)
  if (length(partials) == 0L) stop("No partials to reduce")
  mc.cores <- cores_from_arg(workers)
  if (arity <= 1L) arity <- 2L

  while (length(partials) > 1L) {
    idx <- seq_along(partials)
    groups <- split(idx, ceiling(idx / arity))

    # Parallel group merges via mclapply
    partials <- mclapply(
      X = groups,
      FUN = function(ids, plist) do.call(merge, plist[ids]),
      plist = partials,
      mc.cores = mc.cores
    )
  }

  agg <- partials[[1L]]
  cl0 <- which(agg[, dimension + 1] == 0)
  centres <- old_centres
  if(length(cl0) > 0){
    centres[cl0,] <- matrix(runif(length(cl0) * dimension), nrow = length(cl0), ncol = dimension)
    non0 <- setdiff(seq_len(nrow(agg)), cl0)
    if (length(non0) > 0L) {
      centres[non0,] <- agg[non0, 1:dimension, drop = FALSE] / agg[non0, dimension + 1]
    }
  } else {
    centres <- agg[,1:dimension, drop = FALSE] / agg[,dimension + 1]
  }
  centres
}

# -------- KMeans (mclapply for map) --------

kmeans_frag <- function(fragment_list, num_centres = 10, iterations = 20, epsilon = 1e-9, arity = 50,
                        workers = NULL, iseed) {
  dimensions <- ncol(fragment_list[[1]])
  set.seed(iseed)
  centres <- matrix(runif(num_centres * dimensions), nrow = num_centres, ncol = dimensions)
  if(DEBUG$kmeans_frag){
    cat("Initialized centres:\n")
    print(centres)
  }

  mc.cores <- cores_from_arg(workers)
  iteration <- 0L
  old_centres <- NULL

  while (!converged(old_centres, centres, epsilon, iteration, iterations)) {
    cat(paste0("Doing iteration #", iteration + 1, "/", iterations, ". "))
    iteration_time <- proc.time()[3]
    old_centres <- centres

    # partial_sum task: PARALLEL with mclapply
    partials <- mclapply(
      X = fragment_list,
      FUN = function(frag, centres) partial_sum(frag, centres),
      centres = old_centres,
      mc.cores = mc.cores
    )

    # merge task: PARALLEL batched tree-reduction with mclapply
    centres <- recompute_centres(partials, old_centres, arity, workers = workers)

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

# -------- Arg parsing and main --------

parse_arguments <- function(Minimize) {
  args <- commandArgs(trailingOnly = TRUE)
  seed <- 1L
  numpoints <- 100L
  dimensions <- 2L
  num_centres <- 5L
  fragments <- 10L
  mode <- "uniform"
  iterations <- 20L
  epsilon <- 1e-9
  arity <- 5L
  workers <- NA_integer_
  use_R_default <- FALSE
  is.asking_for_help <- FALSE

  if(length(args) >= 1){
    for (i in seq_along(args)) {
      key <- args[i]
      if (key %in% c("-s","--seed")) seed <- as.integer(args[i+1])
      else if (key %in% c("-n","--numpoints")) numpoints <- as.integer(args[i+1])
      else if (key %in% c("-d","--dimensions")) dimensions <- as.integer(args[i+1])
      else if (key %in% c("-c","--num_centres")) num_centres <- as.integer(args[i+1])
      else if (key %in% c("-f","--fragments")) fragments <- as.integer(args[i+1])
      else if (key %in% c("-m","--mode")) mode <- args[i+1]
      else if (key %in% c("-i","--iterations")) iterations <- as.integer(args[i+1])
      else if (key %in% c("-e","--epsilon")) epsilon <- as.double(args[i+1])
      else if (key %in% c("-a","--arity")) arity <- as.integer(args[i+1])
      else if (key == "--workers") workers <- as.integer(args[i+1])
      else if (key %in% c("-R","--R-default")) use_R_default <- TRUE
      else if (key %in% c("-h","--help")) is.asking_for_help <- TRUE
    }
  }

  if(is.asking_for_help){
    cat("Usage: Rscript kmeans_parallel_linux.R [options]\n")
    cat("  -s, --seed <seed>\n")
    cat("  -n, --numpoints <n>\n")
    cat("  -d, --dimensions <d>\n")
    cat("  -c, --num_centres <k>\n")
    cat("  -f, --fragments <f>\n")
    cat("  -m, --mode <uniform|normal>\n")
    cat("  -i, --iterations <it>\n")
    cat("  -e, --epsilon <eps>\n")
    cat("  -a, --arity <arity>\n")
    cat("      --workers <N>   number of mclapply cores\n")
    cat("  -R, --R-default     use base kmeans on full matrix\n")
    q(status = 0)
  }

  if(numpoints %% fragments){
    stop("Number of fragments is not a factor of number of points!\n")
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
    workers = workers,
    use_R_default = use_R_default
  )
}

print_parameters <- function(p) {
  cat("Parameters:\n")
  cat(sprintf("  Seed: %d\n", p$seed))
  cat(sprintf("  Number of points: %d\n", p$numpoints))
  cat(sprintf("  Dimensions: %d\n", p$dimensions))
  cat(sprintf("  Number of centers: %d\n", p$num_centres))
  cat(sprintf("  Number of fragments: %d\n", p$num_fragments))
  cat(sprintf("  Mode: %s\n", p$mode))
  cat(sprintf("  Iterations: %d\n", p$iterations))
  cat(sprintf("  Epsilon: %.3e\n", p$epsilon))
  cat(sprintf("  Arity: %d\n", p$arity))
  cat(sprintf("  Workers (mclapply cores): %s\n", ifelse(is.na(p$workers), "auto", as.character(p$workers))))
  cat(sprintf("  use_R_default: %s\n", p$use_R_default))
}

# Main
args <- commandArgs(trailingOnly = TRUE)
Minimize <- any(args %in% c("-M","--Minimize"))

params <- parse_arguments(Minimize)
if(!Minimize) print_parameters(params)
attach(params)

set.seed(seed)

for(replicate in 1:6){
  start_time <- proc.time()

  # fill_fragment task: PARALLEL mclapply
  points_per_fragment <- max(1, numpoints %/% num_fragments)
  true_centres <- matrix(runif(num_centres * dimensions), nrow = num_centres, ncol = dimensions)

  frag_args <- replicate(num_fragments, list(true_centres, points_per_fragment, mode), simplify = FALSE)
  fragment_list <- mclapply(
    X = frag_args,
    FUN = function(a) fill_fragment(a),
    mc.cores = cores_from_arg(workers)
  )

  initialization_time <- proc.time()

  if(use_R_default){
    fragment_mat <- do.call(rbind, fragment_list)
    centres <- stats::kmeans(fragment_mat, centers = num_centres, iter.max = iterations)$centers
  } else {
    centres <- kmeans_frag(
      fragment_list = fragment_list,
      num_centres = num_centres,
      iterations = iterations,
      epsilon = epsilon,
      arity = arity,
      workers = workers,
      iseed = seed
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
    ind_centres <- sort(centres[,1], index.return = TRUE)$ix
    ind_true_centres <- sort(true_centres[,1], index.return = TRUE)$ix
    cat("CENTRES\n")
    print(centres[ind_centres, , drop = FALSE])
    cat("TRUE CENTRES\n")
    print(true_centres[ind_true_centres, , drop = FALSE])
    cat("-----------------------------------------\n")
  }
  
  if(Minimize){
    cat("KMEANS_PARALLEL,",
        seed, ",",
        numpoints, ",",
        dimensions, ",",
        num_centres, ",",
        num_fragments, ",",
        mode, ",",
        iterations, ",",
        epsilon, ",",
        arity, ",",
        paste(R.version$major, R.version$minor, sep="."), ",",
        Initialization_time, ",",
        Kmeans_time, ",",
        Total_time, ",",
        replicate,
        "\n", sep = ""
    )
  }
}