# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

# @file functions_linear_regression.R
# @brief This file contains the functions for the linear regression with predictions application
# @version 1.0
# @author Xiran Zhang
# @date 2025-04-28

fit_linear_regression <- function(x_y, dx, dy, arity = 2, use_RCOMPSs = FALSE) {

  nfrag <- length(x_y)
  #x <- vector("list", nfrag)
  #y <- vector("list", nfrag)
  ztz <- vector("list", nfrag)
  zty <- vector("list", nfrag)
  if(use_RCOMPSs){
    # Compute ztz and zty
    for(i in 1:nfrag) {
      #x[[i]] <- task.select_columns(x_y[[i]], 1:dx)
      #y[[i]] <- task.select_columns(x_y[[i]], (dx+1):(dx+dy))
      ztz[[i]] <- task.partial_ztz(x_y[[i]], dx)
      zty[[i]] <- task.partial_zty(x_y[[i]], dx)
    }
    # Merge ztz
    while(length(ztz) > arity){
      ztz_subset <- ztz[1:arity]
      ztz <- ztz[(arity + 1):length(ztz)]
      ztz[[length(ztz) + 1]] <- do.call(task.merge, ztz_subset)
    }
    ztz <- do.call(task.merge, ztz)
    # Merge zty
    while(length(zty) > arity){
      zty_subset <- zty[1:arity]
      zty <- zty[(arity + 1):length(zty)]
      zty[[length(zty) + 1]] <- do.call(task.merge, zty_subset)
    }
    zty <- do.call(task.merge, zty)
    # Compute ztz^(-1) %*% zty
    parameters <- task.compute_model_parameters(ztz, zty)
  }else{
    # Compute ztz and zty
    for(i in 1:nfrag) {
      #x[[i]] <- select_columns(x_y[[i]], 1:dx)
      #y[[i]] <- select_columns(x_y[[i]], (dx+1):(dx+dy))
      ztz[[i]] <- partial_ztz(x_y[[i]], dx)
      zty[[i]] <- partial_zty(x_y[[i]], dx)
    }
    # Merge ztz
    while(length(ztz) > arity){
      ztz_subset <- ztz[1:arity]
      ztz <- ztz[(arity + 1):length(ztz)]
      ztz[[length(ztz) + 1]] <- do.call(merge, ztz_subset)
    }
    ztz <- do.call(merge, ztz)
    # Merge zty
    while(length(zty) > arity){
      zty_subset <- zty[1:arity]
      zty <- zty[(arity + 1):length(zty)]
      zty[[length(zty) + 1]] <- do.call(merge, zty_subset)
    }
    zty <- do.call(merge, zty)
    # Compute ztz^(-1) %*% zty
    parameters <- compute_model_parameters(ztz, zty)
  }

  return(parameters)
}

predict_linear_regression <- function(x, parameters, arity, use_RCOMPSs) {
  nf <- length(x)
  pred <- vector("list", nf)
  if(use_RCOMPSs){
    for(i in 1:nf){
      pred[[i]] <- task.compute_prediction(x[[i]], parameters)
    }
    #offset <- 0
    #while(length(pred) > arity){
    #  if(offset == 0){
    #    pred_subset <- pred[1:arity]
    #    pred <- pred[arity:length(pred)]
    #    pred[[1]] <- do.call(task.row_combine, pred_subset)
    #    offset <- offset + 1
    #  }else{
    #    pred_subset <- pred[1:arity + offset]
    #    pred <- pred[c(1:offset, (arity+offset):length(pred))]
    #    pred[[1+offset]] <- do.call(task.row_combine, pred_subset)
    #    if(offset + arity < length(pred)){
    #      offset <- offset + 1
    #    }else{
    #      offset <- 0
    #    }
    #  }
    #}
    #pred <- do.call(task.row_combine, pred)
  }else{
    for(i in 1:nf){
      pred[[i]] <- compute_prediction(x[[i]], parameters)
    }
    #offset <- 0
    #while(length(pred) > arity){
    #  if(offset == 0){
    #    pred_subset <- pred[1:arity]
    #    pred <- pred[arity:length(pred)]
    #    pred[[1]] <- do.call(row_combine, pred_subset)
    #    offset <- offset + 1
    #  }else{
    #    pred_subset <- pred[1:arity + offset]
    #    pred <- pred[c(1:offset, (arity+offset):length(pred))]
    #    pred[[1+offset]] <- do.call(row_combine, pred_subset)
    #    if(offset + arity < length(pred)){
    #      offset <- offset + 1
    #    }else{
    #      offset <- 0
    #    }
    #  }
    #}
    #pred <- do.call(row_combine, pred)
  }
  return(pred)
}

parse_arguments <- function(Minimize) {

  if(!Minimize){
    cat("Starting parse_arguments\n")
  }

  args <- commandArgs(trailingOnly = TRUE)

  # Define default values
  # Note that if `num_fragments` is not a factor of `numpoints`, the last fragment may give NA due to lack of points.
  seed <- 1
  num_fit <- 9000
  num_pred <- 1000
  dimensions_x <- 2
  dimensions_y <- 2
  num_fragments_fit <- 10
  num_fragments_pred <- 5
  arity <- 2

  # Execution using RCOMPSs
  use_RCOMPSs <- FALSE

  # asking for help
  is.asking_for_help <- FALSE

  # Compare accuracy?
  compare_accuracy <- FALSE

  # Parse arguments
  if(length(args) >= 1){
    for (i in 1:length(args)) {
      if (args[i] == "-s") {
        seed <- as.integer(args[i + 1])
      } else if (args[i] == "--seed") {
        seed <- as.integer(args[i + 1])
      } else if (args[i] == "-n") {
        num_fit <- as.integer(args[i + 1])
      } else if (args[i] == "--num_fit") {
        num_fit <- as.integer(args[i + 1])
      } else if (args[i] == "-N") {
        num_pred <- as.integer(args[i + 1])
      } else if (args[i] == "--num_pred") {
        num_pred <- as.integer(args[i + 1])
      } else if (args[i] == "-d") {
        dimensions_x <- as.integer(args[i + 1])
      } else if (args[i] == "--dimensions_x") {
        dimensions_x <- as.integer(args[i + 1])
      } else if (args[i] == "-D") {
        dimensions_y <- as.integer(args[i + 1])
      } else if (args[i] == "--dimensions_y") {
        dimensions_y <- as.integer(args[i + 1])
      } else if (args[i] == "-f") {
        num_fragments_fit <- as.integer(args[i + 1])
      } else if (args[i] == "--fragments_fit") {
        num_fragments_fit <- as.integer(args[i + 1])
      } else if (args[i] == "-F") {
        num_fragments_pred <- as.integer(args[i + 1])
      } else if (args[i] == "--fragments_pred") {
        num_fragments_pred <- as.integer(args[i + 1])
      } else if (args[i] == "-a") {
        arity <- as.integer(args[i + 1])
      } else if (args[i] == "--arity") {
        arity <- as.integer(args[i + 1])
      } else if (args[i] == "-C") {
        use_RCOMPSs <- TRUE
      } else if (args[i] == "--RCOMPSs") {
        use_RCOMPSs <- TRUE
      } else if (args[i] == "--compare_accuracy") {
        compare_accuracy <- TRUE
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
    cat("  -s, --seed <seed>                          Seed for random number generator\n")
    cat("  -n, --num_fit <num_fit>                    Number of fitting points\n")
    cat("  -N, --num_pred <num_pred>                  Number of predicting points\n")
    cat("  -d, --dimensions_x <dimensions_x>          Number of X dimensions\n")
    cat("  -D, --dimensions_y <dimensions_y>          Number of Y dimensions\n")
    cat("  -f, --fragments_fit <num_fragments_fit>    Number of fragments of the fitting data\n")
    cat("  -F, --fragments_pred <num_fragments_pred>  Number of fragments of the prediction data\n")
    cat("  -r, --arity <arity>                        Integer: Arity of the merge\n")
    cat("  -C, --RCOMPSs <use_RCOMPSs>                Boolean: Use RCOMPSs parallelization?\n")
    cat("  -M, --Minimize <Minimize>                  Boolean: Minimize printout?\n")
    cat("  --compare_accuracy <compare_accuracy>      Boolean: Compare accuracy?\n")
    cat("  -h, --help                                 Show this help message\n")
    q(status = 0)
  }

  return(list(
              seed = seed,
              num_fit = num_fit,
              num_pred = num_pred,
              dimensions_x = dimensions_x,
              dimensions_y = dimensions_y,
              num_fragments_fit = num_fragments_fit,
              num_fragments_pred = num_fragments_pred,
              arity = arity,
              use_RCOMPSs = use_RCOMPSs,
              compare_accuracy = compare_accuracy
              ))
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
  cat("  use_RCOMPSs:", params$use_RCOMPSs, "\n")
  cat("  Compare accuracy?", params$compare_accuracy, "\n")
}
