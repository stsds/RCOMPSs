suppressPackageStartupMessages({
  library(future)
})

DEBUG <- list()

## Tasks (pure R, vectorized)

LR_fill_fragment <- function(params_LR_fill_fragment, true_coeff){
  num_frag <- params_LR_fill_fragment$dim[1]
  dimension_x <- params_LR_fill_fragment$dim[2]
  dimension_y <- params_LR_fill_fragment$dim[3]
  x_frag <- matrix(runif(num_frag * dimension_x), nrow = num_frag, ncol = dimension_x)
  y_frag <- cbind(1, x_frag) %*% true_coeff
  M <- matrix(rnorm(num_frag * dimension_y), nrow = num_frag, ncol = dimension_y)
  y_frag <- y_frag + M
  X_Y <- cbind(x_frag, y_frag)
  return(X_Y)
}

LR_genpred <- function(params_LR_genpred){
  num_frag <- params_LR_genpred$n
  dimension <- params_LR_genpred$d
  x_pred <- matrix(runif(num_frag * dimension), nrow = num_frag, ncol = dimension)
  return(x_pred)
}

parse_arguments <- function(Minimize) {
  if(!Minimize){
    cat("Starting parse_arguments\n")
  }

  args <- commandArgs(trailingOnly = TRUE)
  seed <- 1
  num_fit <- 9000
  num_pred <- 1000
  dimensions_x <- 2
  dimensions_y <- 2
  num_fragments_fit <- 10
  num_fragments_pred <- 5
  arity <- 2
  use_RCOMPSs <- FALSE
  compare_accuracy <- FALSE
  cores <- NA_integer_
  is.asking_for_help <- FALSE
  replicates <- 1

  for (i in seq_along(args)) {
    val <- args[i + 1]
    switch(args[i],
      "-s" =, "--seed" = { seed <- as.integer(val) },
      "-n" =, "--num_fit" = { num_fit <- as.integer(val) },
      "-N" =, "--num_pred" = { num_pred <- as.integer(val) },
      "-d" =, "--dimensions_x" = { dimensions_x <- as.integer(val) },
      "-D" =, "--dimensions_y" = { dimensions_y <- as.integer(val) },
      "-f" =, "--fragments_fit" = { num_fragments_fit <- as.integer(val) },
      "-F" =, "--fragments_pred" = { num_fragments_pred <- as.integer(val) },
      "-a" =, "--arity" = { arity <- as.integer(val) },
      "-C" =, "--RCOMPSs" = { use_RCOMPSs <- TRUE },
      "--replicates" = { replicates <- as.integer(val) },
      "--compare_accuracy" = { compare_accuracy <- TRUE },
      "--cores" = { cores <- as.integer(val) },
      "-h" =, "--help" = { is.asking_for_help <- TRUE }
    )
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
    cat("      --replicates <replicates>              Number of replicates (default: 1)\n")
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
    cores = cores,
    replicates = replicates
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

auto_cores <- max(1L, future::availableCores() - 0L)
ncores <- if (is.na(cores)) auto_cores else max(1L, as.integer(cores))

set.seed(seed)
n <- num_fit
N <- num_pred
d <- dimensions_x
D <- dimensions_y

true_coeff <- matrix(round(runif((d+1)*D, -10, 10)), nrow = d + 1, ncol = D)
for(j in 1:D){
  while(all(true_coeff[-1,j] == 0)){
    true_coeff[-1,j] <- round(runif(d, -10, 10))
  }
}

plan(multisession, workers = ncores)

for(replicate in 1:replicates){
  cat("Doing replicate", replicate, "...\n")

  start_time <- proc.time()

  fit_chunk <- n / num_fragments_fit
  pred_chunk <- N / num_fragments_pred
  if (fit_chunk != floor(fit_chunk) || pred_chunk != floor(pred_chunk)) {
    stop("num_fit and num_pred must be divisible by their respective fragment counts.")
  }

  # Parallel data generation using future
  X_Y <- vector("list", length(num_fragments_fit))
  for (i in seq_along(num_fragments_fit)) {
    X_Y[[i]] <- future({
      set.seed(seed + i)
      fit_params <- list(dim = c(fit_chunk, d, D))
      LR_fill_fragment(fit_params, true_coeff)
    }, seed = NULL)
  }

  PRED <- vector("list", length(num_fragments_pred))
  for (i in seq_along(num_fragments_pred)) {
    PRED[[i]] <- future({
      set.seed(seed + 10000L + i)
      pred_params <- list(n = pred_chunk, d = d)
      LR_genpred(pred_params)
    }, seed = NULL)
  }

  # Parallel computation of ztz and zty
  ztz_futures <- vector("list", length(X_Y))
  zty_futures <- vector("list", length(X_Y))
  for (i in seq_along(X_Y)) {
    if("Future" %in% class(X_Y[[i]])){
      X_Y[[i]] <- value(X_Y[[i]])
    }
    ztz_futures[[i]] <- future({
      x <- X_Y[[i]][, 1:d, drop = FALSE]
      x <- cbind(1, x)
      t(x) %*% x
    })
    zty_futures[[i]] <- future({
      x <- X_Y[[i]][, 1:d, drop = FALSE]
      y <- X_Y[[i]][, (d+1):ncol(X_Y[[i]]), drop = FALSE]
      x <- cbind(1, x)
      t(x) %*% y
    })
  }
  ztz_list <- value(ztz_futures)
  ztz <- Reduce("+", ztz_list)
  zty_list <- value(zty_futures)
  zty <- Reduce("+", zty_list)
  parameters <- solve(ztz, zty)

  # Parallel prediction
  pred_futures <- vector("list", length(PRED))
  for (i in seq_along(PRED)) {
    if("Future" %in% class(PRED[[i]])){
      PRED[[i]] <- value(PRED[[i]])
    }
    pred_futures[[i]] <- future({
      x <- cbind(1, PRED[[i]])
      x %*% parameters
    })
  }
  predictions <- value(pred_futures)

  linear_regression_time <- proc.time()
  LR_time <- round(linear_regression_time[3] - start_time[3], 3)

  if(compare_accuracy){
    X_Y_mat <- do.call(rbind, X_Y)
    PRED_mat <- do.call(rbind, PRED)
    predictions_mat <- do.call(rbind, predictions)

    X <- X_Y_mat[,1:dimensions_x, drop = FALSE]
    Y <- X_Y_mat[,(dimensions_x+1):(dimensions_x+dimensions_y), drop = FALSE]

    start_lm <- proc.time()
    df <- data.frame(Y, X)
    colnames(df) <- c(paste0("Y", seq_len(D)), paste0("X", seq_len(d)))
    fml <- as.formula(
      paste(paste0("cbind(", paste0("Y", seq_len(D), collapse = ","), ")"),
            "~",
            paste0(paste0("X", seq_len(d)), collapse = " + "))
    )
    model_base <- lm(fml, data = df)
    coeff <- coefficients(model_base)
    beta_hat <- matrix(0, nrow = d + 1, ncol = D)
    rownames(beta_hat) <- c("(Intercept)", paste0("X", seq_len(d)))
    colnames(beta_hat) <- paste0("Y", seq_len(D))
    for (j in seq_len(D)) {
      cj <- coeff[, j]
      beta_hat[1, j] <- cj["(Intercept)"]
      for (k in seq_len(d)) {
        nm <- paste0("X", k)
        beta_hat[1 + k, j] <- if (nm %in% names(cj)) cj[nm] else 0
      }
    }
    predictions_base <- cbind(1, PRED_mat) %*% beta_hat
    end_lm <- proc.time()
    lm_time <- round(end_lm[3] - start_lm[3], 3)
    if(!Minimize){
      cat("\nTrue coefficients:\n"); print(round(true_coeff, 2))
      cat("\nEstimated coefficients (parallel):\n"); print(round(parameters, 2))
      cat("\n`lm` coefficients (reformatted):\n"); print(round(beta_hat, 2))
      cat("\nSquared error between predictions and lm baseline: ",
          sum((predictions_mat - predictions_base)^2), "\n", sep = "")
    }
  }

  cat("-----------------------------------------\n")
  cat("-------------- RESULTS ------------------\n")
  cat("-----------------------------------------\n")
  cat("Linear regression time:", LR_time, "seconds\n")
  if(compare_accuracy) cat("Base R lm time:", lm_time, "seconds\n")
  cat("-----------------------------------------\n")

  if(Minimize){
    cat(paste0("LR_FUTURE,", seed, ",", num_fit, ",", num_pred, ",", dimensions_x, ",", dimensions_y, ",", num_fragments_fit, ",", num_fragments_pred, ",", arity, ",", cores, ",", compare_accuracy, ",", Minimize, ",", LR_time, ",", replicate, "\n"))
  }

  rm(X_Y, parameters, predictions)
}