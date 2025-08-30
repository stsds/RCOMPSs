# linear_regression_parallel.R

suppressPackageStartupMessages({
  # parallel is part of base R, no installation needed
  library(parallel)
  library(purrr)
})

DEBUG <- list(
  LR_fill_fragment = FALSE,
  partial_ztz = FALSE,
  partial_zty = FALSE,
  compute_model_parameters = FALSE,
  merge = FALSE
)

## Tasks (pure R, vectorized)

LR_fill_fragment <- function(params_LR_fill_fragment, true_coeff, seed = NULL){
  num_frag <- params_LR_fill_fragment$dim[1]
  dimension_x <- params_LR_fill_fragment$dim[2]
  dimension_y <- params_LR_fill_fragment$dim[3]
  if(!is.null(seed)) set.seed(seed)
  # Generate X
  x_frag <- matrix(runif(num_frag * dimension_x), nrow = num_frag, ncol = dimension_x)
  # Create the response variable with some noise
  y_frag <- cbind(1, x_frag) %*% true_coeff
  M <- matrix(rnorm(num_frag * dimension_y), nrow = num_frag, ncol = dimension_y)
  y_frag <- y_frag + M
  X_Y <- cbind(x_frag, y_frag)
  return(X_Y)
}

LR_genpred <- function(params_LR_genpred, seed = NULL){
  num_frag <- params_LR_genpred$n
  dimension <- params_LR_genpred$d
  if(!is.null(seed)) set.seed(seed)
  x_pred <- matrix(runif(num_frag * dimension), nrow = num_frag, ncol = dimension)
  return(x_pred)
}

partial_ztz <- function(x_y, dx) {
  x <- x_y[,1:dx, drop = FALSE]
  x <- cbind(1, x)
  t(x) %*% x
}

partial_zty <- function(x_y, dx) {
  x <- x_y[,1:dx, drop = FALSE]
  y <- x_y[,(dx+1):ncol(x_y), drop = FALSE]
  x <- cbind(1, x)
  t(x) %*% y
}

compute_model_parameters <- function(ztz, zty) {
  solve(ztz, zty)
}

compute_prediction <- function(x, parameters){
  x <- cbind(1, x)
  x %*% parameters
}

row_combine <- function(...){
  do.call(rbind, list(...))
}

merge <- function(...){
  input <- list(...)
  input_len <- length(input)
  if(input_len == 1){
    return(input[[1]])
  }else if(input_len >= 2){
    accum <- input[[1]]
    for(i in 2:input_len){
      accum <- accum + input[[i]]
    }
    return(accum)
  }else{
    stop("Wrong input in `merge`!\n")
  }
}

## Parallel helpers

# Parallel map with load balancing using parLapplyLB
pmap <- function(cl, X, FUN, ..., .export = NULL) {
  # Ensure required symbols are present on workers
  if (length(cl)) {
    if (!is.null(.export) && length(.export)) {
      clusterExport(cl, varlist = .export, envir = environment())
    }
    parLapplyLB(cl, X, function(x) FUN(x, ...))
  } else {
    lapply(X, function(x) FUN(x, ...))
  }
}

# Parallel pairwise reduce to honor arity and scalability
# reducer combines two elements; we do pairwise rounds until single value
pairwise_reduce <- function(cl, items, reducer) {
  if (length(items) == 0) stop("Nothing to reduce")
  current <- items
  while (length(current) > 1) {
    # Pair indices
    n <- length(current)
    idx <- split(seq_len(n), ceiling(seq_along(current)/2))
    # Map pairs in parallel
    current <- unlist(
      pmap(cl, idx, function(ind) {
        pair <- current[ind]
        if (length(pair) == 1) {
          pair[[1]]
        } else {
          reducer(pair[[1]], pair[[2]])
        }
      }),
      recursive = FALSE
    )
  }
  current[[1]]
}

## Functions (parallelized)

fit_linear_regression <- function(x_y, dx, dy, arity = 2, cl = NULL) {
  nfrag <- length(x_y)

  # Compute ztz and zty in parallel
  ztz_list <- pmap(cl, x_y, function(xi) partial_ztz(xi, dx), .export = c("partial_ztz"))
  zty_list <- pmap(cl, x_y, function(xi) partial_zty(xi, dx), .export = c("partial_zty"))

  # Efficient reduction honoring arity using pairwise parallel reduction.
  # If arity > 2, we still use pairwise reduction for better parallel efficiency.
  # This matches merge semantics (elementwise sum).
  ztz <- pairwise_reduce(cl, ztz_list, function(a,b) merge(a,b))
  zty <- pairwise_reduce(cl, zty_list, function(a,b) merge(a,b))

  # Solve for parameters
  parameters <- compute_model_parameters(ztz, zty)
  parameters
}

predict_linear_regression <- function(x, parameters, cl = NULL) {
  pmap(cl, x, function(xi) compute_prediction(xi, parameters), .export = c("compute_prediction"))
}

parse_arguments <- function(Minimize) {
  if(!Minimize){
    cat("Starting parse_arguments\n")
  }

  args <- commandArgs(trailingOnly = TRUE)

  # Defaults
  seed <- 1
  num_fit <- 9000
  num_pred <- 1000
  dimensions_x <- 2
  dimensions_y <- 2
  num_fragments_fit <- 10
  num_fragments_pred <- 5
  arity <- 2
  use_RCOMPSs <- FALSE  # ignored; retained for compatibility
  compare_accuracy <- FALSE
  cores <- NA_integer_ # auto-detect

  is.asking_for_help <- FALSE

  if(length(args) >= 1){
    for (i in 1:length(args)) {
      if (args[i] == "-s" || args[i] == "--seed") {
        seed <- as.integer(args[i + 1])
      } else if (args[i] == "-n" || args[i] == "--num_fit") {
        num_fit <- as.integer(args[i + 1])
      } else if (args[i] == "-N" || args[i] == "--num_pred") {
        num_pred <- as.integer(args[i + 1])
      } else if (args[i] == "-d" || args[i] == "--dimensions_x") {
        dimensions_x <- as.integer(args[i + 1])
      } else if (args[i] == "-D" || args[i] == "--dimensions_y") {
        dimensions_y <- as.integer(args[i + 1])
      } else if (args[i] == "-f" || args[i] == "--fragments_fit") {
        num_fragments_fit <- as.integer(args[i + 1])
      } else if (args[i] == "-F" || args[i] == "--fragments_pred") {
        num_fragments_pred <- as.integer(args[i + 1])
      } else if (args[i] == "-a" || args[i] == "--arity") {
        arity <- as.integer(args[i + 1])
      } else if (args[i] == "-C" || args[i] == "--RCOMPSs") {
        use_RCOMPSs <- FALSE  # deprecated; forced to FALSE
      } else if (args[i] == "--compare_accuracy") {
        compare_accuracy <- TRUE
      } else if (args[i] == "--cores") {
        cores <- as.integer(args[i + 1])
      } else if (args[i] == "-h" || args[i] == "--help") {
        is.asking_for_help <- TRUE
      }
    }
  }

  if(is.asking_for_help){
    cat("Usage: Rscript linear_regression_parallel.R [options]\n")
    cat("Options:\n")
    cat("  -s, --seed <seed>                          Seed for RNG\n")
    cat("  -n, --num_fit <num_fit>                    Number of fitting points\n")
    cat("  -N, --num_pred <num_pred>                  Number of predicting points\n")
    cat("  -d, --dimensions_x <dimensions_x>          Number of X dimensions\n")
    cat("  -D, --dimensions_y <dimensions_y>          Number of Y dimensions\n")
    cat("  -f, --fragments_fit <num_fragments_fit>    Number of fragments (fit)\n")
    cat("  -F, --fragments_pred <num_fragments_pred>  Number of fragments (pred)\n")
    cat("  -a, --arity <arity>                        Arity of merge (kept for compat)\n")
    cat("      --cores <cores>                        Parallel workers (default: all)\n")
    cat("      --compare_accuracy                     Compare with base lm\n")
    cat("  -h, --help                                 Show this help message\n")
    q(status = 0)
  }

  list(
    seed = seed,
    num_fit = num_fit,
    num_pred = num_pred,
    dimensions_x = dimensions_x,
    dimensions_y = dimensions_y,
    num_fragments_fit = num_fragments_fit,
    num_fragments_pred = num_fragments_pred,
    arity = arity,
    use_RCOMPSs = FALSE,
    compare_accuracy = compare_accuracy,
    cores = cores
  )
}

print_parameters <- function(params) {
  cat("Parameters:\n")
  cat("  Seed:", params$seed, "\n")
  cat("  Number of fitting points:", params$num_fit, "\n")
  cat("  Number of predicting points:", params$num_pred, "\n")
  cat("  X dimensions:", params$dimensions_x, "\n")
  cat("  Y dimensions:", params$dimensions_y, "\n")
  cat("  Number of fragments of the fitting data:", params$num_fragments_fit, "\n")
  cat("  Number of fragments of the predicting data:", params$num_fragments_pred, "\n")
  cat("  Arity:", params$arity, "\n")
  cat("  Compare accuracy?", params$compare_accuracy, "\n")
  cat("  Cores:", ifelse(is.na(params$cores), "auto", params$cores), "\n")
}

# Main

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
  cat("Loading functions ... Done.\n")
}

params <- parse_arguments(Minimize)
print_parameters(params)
attach(params)
if(!Minimize){
  cat("Done.\n")
}

# Set up cluster
auto_cores <- max(1L, detectCores(logical = TRUE) - 0L)
ncores <- if (is.na(cores)) auto_cores else max(1L, as.integer(cores))
cl <- if (ncores > 1L) makeCluster(ncores, type = "PSOCK") else NULL
on.exit({
  if (!is.null(cl)) stopCluster(cl)
}, add = TRUE)

# Export needed symbols to workers
if (!is.null(cl)) {
  clusterSetRNGStream(cl, seed) # ensure reproducible RNG streams
  clusterExport(cl, varlist = c(
    "DEBUG",
    "LR_fill_fragment","LR_genpred",
    "partial_ztz","partial_zty",
    "compute_model_parameters","compute_prediction",
    "merge","row_combine",
    "pairwise_reduce","pmap"
  ), envir = environment())
}

set.seed(seed)
n <- num_fit
N <- num_pred
d <- dimensions_x
D <- dimensions_y

# Generate random regression coefficients (in master, deterministic)
true_coeff <- matrix(round(runif((d+1)*D, -10, 10)), nrow = d + 1, ncol = D)
for(j in 1:D){
  while(all(true_coeff[-1,j] == 0)){
    true_coeff[-1,j] <- round(runif(d, -10, 10))
  }
}

for(replicate in 1:1){
  cat("Doing replicate", replicate, "...\n")

  start_time <- proc.time()

  # Parallel data generation across fragments with deterministic per-fragment seeds
  # Split sizes (equal-sized fragments assumed by your code)
  fit_chunk <- n / num_fragments_fit
  pred_chunk <- N / num_fragments_pred
  if (fit_chunk != floor(fit_chunk) || pred_chunk != floor(pred_chunk)) {
    stop("num_fit and num_pred must be divisible by their respective fragment counts.")
  }

  fit_params <- replicate(num_fragments_fit, list(dim = c(fit_chunk, d, D)), simplify = FALSE)
  pred_params <- replicate(num_fragments_pred, list(n = pred_chunk, d = d), simplify = FALSE)

  # Seeds per fragment to ensure reproducibility irrespective of scheduling
  fit_seeds <- seed + seq_len(num_fragments_fit)
  pred_seeds <- seed + 100000L + seq_len(num_fragments_pred)

  X_Y <- pmap(cl, seq_along(fit_params), function(i) {
    LR_fill_fragment(fit_params[[i]], true_coeff, seed = fit_seeds[i])
  }, .export = c("LR_fill_fragment"))

  PRED <- pmap(cl, seq_along(pred_params), function(i) {
    LR_genpred(pred_params[[i]], seed = pred_seeds[i])
  }, .export = c("LR_genpred"))

  # Fit the model (parallel)
  model <- fit_linear_regression(X_Y, d, D, arity = arity, cl = cl)

  # Predict using the model (parallel)
  predictions <- predict_linear_regression(PRED, model, cl = cl)

  linear_regression_time <- proc.time()
  LR_time <- round(linear_regression_time[3] - start_time[3], 3)

  # Optional accuracy comparison
  if(compare_accuracy){
    X_Y_mat <- do.call(rbind, X_Y)
    PRED_mat <- do.call(rbind, PRED)
    predictions_mat <- do.call(rbind, predictions)

    X <- X_Y_mat[,1:dimensions_x, drop = FALSE]
    Y <- X_Y_mat[,(dimensions_x+1):(dimensions_x+dimensions_y), drop = FALSE]

    start_lm <- proc.time()
    # Fit multivariate lm with intercept and X columns
    # Construct formula Y ~ X with matrix X
    df <- data.frame(Y, X)
    # Name columns to avoid lm term confusion
    colnames(df) <- c(paste0("Y", seq_len(D)), paste0("X", seq_len(d)))
    fml <- as.formula(
      paste(paste0("cbind(", paste0("Y", seq_len(D), collapse = ","), ")"),
            "~",
            paste0(paste0("X", seq_len(d)), collapse = " + "))
    )
    model_base <- lm(fml, data = df)
    coeff <- coefficients(model_base)  # (Intercept and Xk for each response)
    # Build coefficient matrix to match our parameter layout
    # Our layout: rows: (Intercept, X1..Xd), cols: Y1..YD
    beta_hat <- matrix(0, nrow = d + 1, ncol = D)
    rownames(beta_hat) <- c("(Intercept)", paste0("X", seq_len(d)))
    colnames(beta_hat) <- paste0("Y", seq_len(D))
    for (j in seq_len(D)) {
      cj <- coeff[, j]
      beta_hat[,"Y"[1]] # placeholder to appease lintr
      beta_hat[1, j] <- cj["(Intercept)"]
      for (k in seq_len(d)) {
        nm <- paste0("X", k)
        beta_hat[1 + k, j] <- if (nm %in% names(cj)) cj[nm] else 0
      }
    }
    predictions_base <- cbind(1, PRED_mat) %*% beta_hat
    end_lm <- proc.time()
    lm_time <- round(end_lm[3] - start_lm[3], 3)

    cat("\nTrue coefficients:\n"); print(round(true_coeff, 2))
    cat("\nEstimated coefficients (parallel):\n"); print(round(model, 2))
    cat("\n`lm` coefficients (reformatted):\n"); print(round(beta_hat, 2))
    cat("\nSquared error between predictions and lm baseline: ",
        sum((predictions_mat - predictions_base)^2), "\n", sep = "")
  }

  cat("-----------------------------------------\n")
  cat("-------------- RESULTS ------------------\n")
  cat("-----------------------------------------\n")
  cat("Linear regression time:", LR_time, "seconds\n")
  if(compare_accuracy) cat("Base R lm time:", lm_time, "seconds\n")
  cat("-----------------------------------------\n")

  if(Minimize){
    cat("LR_RES,seed,num_fit,num_pred,dimensions_x,dimensions_y,num_fragments_fit,num_fragments_pred,arity,use_RCOMPSs,compare_accuracy,Minimize,LR_time,run\n")
    cat(paste0("LR_res,", seed, ",", num_fit, ",", num_pred, ",", dimensions_x, ",", dimensions_y, ",", num_fragments_fit, ",", num_fragments_pred, ",", arity, ",", FALSE, ",", compare_accuracy, ",", Minimize, ",", LR_time, ",", replicate, "\n"))
  }

  rm(X_Y, model, predictions)
}