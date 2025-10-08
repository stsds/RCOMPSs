# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

# @file tasks_linear_regression.R
# @brief This file contains the tasks of the linear regression with predictions application
# @version 1.0
# @author Xiran Zhang
# @date 2025-04-28

DEBUG <- list(
              LR_fill_fragment = FALSE,
              partial_ztz = FALSE,
              partial_zty = FALSE,
              compute_model_parameters = FALSE,
              merge = FALSE
)

LR_fill_fragment <- function(num_frag, dimension_x, dimension_y, true_coeff){
  if(DEBUG$LR_fill_fragment){
    cat("Doing LR_fill_fragment ...\n")
    cat(paste0("num_frag = ", num_frag, "; dimension_x = ", dimension_x, "; dimension_y = ", dimension_y, "\n"))
    cat("class(true_coeff):", class(true_coeff), "\n")
    cat("typeof(true_coeff):", typeof(true_coeff), "\n")
    cat("Printing true_coeff\n"); print(true_coeff)
  }
  # Generate X
  x_frag <- matrix(runif(num_frag * dimension_x), nrow = num_frag, ncol = dimension_x)
  # Create the response variable with some noise
  y_frag <- cbind(1, x_frag) %*% true_coeff
  M <- matrix(rnorm(num_frag * dimension_y), nrow = num_frag, ncol = dimension_y)
  y_frag <- y_frag + M

  cbind(x_frag, y_frag)
}

LR_genpred <- function(num_frag, dimension){
  # Generate random data for prediction
  matrix(runif(num_frag * dimension), nrow = num_frag, ncol = dimension)
}

partial_ztz <- function(x_y, dx) {
  if(DEBUG$partial_ztz){
    cat("Executing task: partial_ztz\n")
    cat("In partial_ztz, x_y: type is", typeof(x_y), "class is", class(x_y), "\n")
  }
  x <- x_y[,1:dx]
  if(DEBUG$partial_ztz){
    cat("In partial_ztz, x:\n")
    print(x)
  }
  x <- cbind(1, x)
  if(DEBUG$partial_ztz){
    cat("Executing task: partial_ztz\n")
  }
  ztz <- t(x) %*% x
  if(DEBUG$partial_ztz){
    cat("Executing task: partial_ztz ---- Success!\n")
  }
  return(ztz)
}

partial_zty <- function(x_y, dx) {
  if(DEBUG$partial_zty){
    cat("Executing task: partial_zty\n")
  }
  x <- x_y[,1:dx]
  y <- x_y[,(dx+1):ncol(x_y)]
  x <- cbind(1, x)
  zty <- t(x) %*% y
  if(DEBUG$partial_zty){
    cat("Executing task: partial_zty ---- Success!\n")
  }
  return(zty)
}

compute_model_parameters <- function(ztz, zty) {
  params <- solve(ztz, zty)
  return(params)
}

compute_prediction <- function(x, parameters){
  x <- cbind(1, x)
  return(x %*% parameters)
}

row_combine <- function(...){
  do.call(rbind, list(...))
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
    for(i in 1:input_len){
      cat("Input dimension", i, dim(input[[i]]), "\n")
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
  # [COR1 COR2 COR3] NUM_POINTS
}
