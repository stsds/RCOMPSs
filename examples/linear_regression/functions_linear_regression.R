fit_linear_regression <- function(x, y, fit_intercept = TRUE, numrows = 2, arity = 2, use_RCOMPSs = FALSE) {

  n_features <- ncol(x)
  n_targets <- ncol(y)
  ztz <- compute_ztz(x, fit_intercept, numrows, arity, use_RCOMPSs)
  zty <- compute_zty(x, y, fit_intercept, numrows, arity, use_RCOMPSs)
  if(use_RCOMPSs){
    ztz <- compss_wait_on(ztz)
    zty <- compss_wait_on(zty)
  }
  params <- compute_model_parameters(ztz, zty, fit_intercept)

  list(intercept = params[[1]], coef = params[[2]], n_features = n_features, n_targets = n_targets)
}

predict_linear_regression <- function(model, x) {
  return(as.numeric(as.matrix(x) %*% model$coef + model$intercept))
}

save_model <- function(model, filepath) {
  saveRDS(model, file = filepath)
}

load_model <- function(filepath) {
  readRDS(file = filepath)
}

row_range <- function(ind, nr, n){
  if(ind * nr <= n){
    return(( (ind - 1) * nr + 1 ):( ind * nr ))
  }else{
    return(( (ind - 1) * nr + 1 ):n)
  }
}

compute_ztz <- function(x, fit_intercept, numrows, arity, use_RCOMPSs) {
  partials <- list()
  i <- 1
  total_rows <- nrow(x)
  if(use_RCOMPSs){
    while( (i-1)*numrows < total_rows ) {
      block_x <- x[row_range(i, numrows, total_rows), , drop = FALSE]
      partials[[i]] <- task.partial_ztz(block_x, fit_intercept)
      i <- i + 1
    }
  }else{
    while( (i-1)*numrows < total_rows ) {
      partials[[i]] <- partial_ztz(x[row_range(i, numrows, total_rows), , drop = FALSE], fit_intercept)
      i <- i + 1
    }
  }
  if(use_RCOMPSs){
    partials <- do.call(task.merge, partials)
    return(partials)
  }else{
    return(Reduce("+", partials))
  }
}

compute_zty <- function(x, y, fit_intercept, numrows, arity, use_RCOMPSs) {
  partials <- list()
  i <- 1
  total_rows <- nrow(x)
  if(use_RCOMPSs){
    while( (i-1)*numrows < total_rows ) {
      block_x <- x[row_range(i, numrows, total_rows), , drop = FALSE]
      block_y <- y[row_range(i, numrows, total_rows), , drop = FALSE]
      partials[[i]] <- task.partial_zty(block_x, block_y, fit_intercept)
      i <- i + 1
    }
  }else{
    while( (i-1)*numrows < total_rows ) {
      partials[[i]] <- partial_zty(x[row_range(i, numrows, total_rows), , drop = FALSE], 
                                   y[row_range(i, numrows, total_rows), , drop = FALSE], 
                                   fit_intercept)
      i <- i + 1
    }
  }
  if(use_RCOMPSs){
    partials <- do.call(task.merge, partials)
    return(partials)
  }else{
    return(Reduce("+", partials))
  }
}

parse_arguments <- function(Minimize) {

  if(!Minimize){
    cat("Starting parse_arguments\n")
  }

  args <- commandArgs(trailingOnly = TRUE)

  # Define default values
  # Note that if `num_fragments` is not a factor of `numpoints`, the last fragment may give NA due to lack of points.
  seed <- 1
  numpoints <- 9000
  dimensions <- 2
  numrows <- 1000
  arity <- 2

  # Execution using RCOMPSs
  use_RCOMPSs <- FALSE

  # asking for help
  is.asking_for_help <- FALSE

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
      } else if (args[i] == "-r") {
        numrows <- as.integer(args[i + 1])
      } else if (args[i] == "--numrows") {
        numrows <- as.integer(args[i + 1])
      } else if (args[i] == "-a") {
        arity <- as.integer(args[i + 1])
      } else if (args[i] == "--arity") {
        arity <- as.integer(args[i + 1])
      } else if (args[i] == "-C") {
        use_RCOMPSs <- TRUE
      } else if (args[i] == "--RCOMPSs") {
        use_RCOMPSs <- TRUE
      } else if (args[i] == "-h") {
        is.asking_for_help <- TRUE
      } else if (args[i] == "--help") {
        is.asking_for_help <- TRUE
      }
    }
  }

  if(is.asking_for_help){
    cat("Usage: Rscript linear_regression.R [options]\n")
    cat("Options:\n")
    cat("  -s, --seed <seed>                Seed for random number generator\n")
    cat("  -n, --numpoints <numpoints>      Number of points\n")
    cat("  -d, --dimensions <dimensions>    Number of dimensions\n")
    cat("  -r, --numrows <numrows>          Number of rows to create the submatrix\n")
    cat("  -r, --arity <arity>              Integer: Arity of the merge\n")
    cat("  -C, --RCOMPSs <use_RCOMPSs>      Boolean: Use RCOMPSs parallelization?\n")
    cat("  -M, --Minimize <Minimize>        Boolean: Minimize printout?\n")
    cat("  -h, --help                       Show this help message\n")
    q(status = 0)
  }

  return(list(
              seed = seed,
              numpoints = numpoints,
              dimensions = dimensions,
              numrows = numrows,
              arity = arity,
              use_RCOMPSs = use_RCOMPSs
              ))
}

print_parameters <- function(params) {
  cat("Parameters:\n")
  cat(sprintf("  Seed: %d\n", params$seed))
  cat(sprintf("  Number of points: %d\n", params$numpoints))
  cat(sprintf("  Dimensions: %d\n", params$dimensions))
  cat(sprintf("  Number of rows: %d\n", params$numrows))
  cat(sprintf("  Number of rows: %d\n", params$arity))
  cat("  use_RCOMPSs:", params$use_RCOMPSs, "\n")
}
