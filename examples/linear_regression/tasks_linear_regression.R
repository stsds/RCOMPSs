DEBUG <- list(
  partial_ztz = FALSE,
  partial_zty = FALSE,
  compute_model_parameters = FALSE,
  merge = FALSE
)

LR_fill_fragment <- function(params_LR_fill_fragment){
  num_frag <- params_LR_fill_fragment$dim[1]
  dimension_x <- params_LR_fill_fragment$dim[2]
  dimension_y <- params_LR_fill_fragment$dim[3]
  true_coeff <- params_LR_fill_fragment$true_coeff
  # Generate X
  x_frag <- matrix(runif(num_frag * dimension_x), nrow = num_frag, ncol = dimension_x)
  # Create the response variable with some noise
  y_frag <- cbind(1, x_frag) %*% true_coeff
  M <- matrix(rnorm(num_frag * dimension_y), nrow = num_frag, ncol = dimension_y)
  y_frag <- y_frag + M

  X_Y <- cbind(x_frag, y_frag)
  return(X_Y)
}

LR_genpred <- function(params_LR_genpred){
  num_frag <- params_LR_genpred$n
  dimension <- params_LR_genpred$d
  # Generate random data for prediction
  x_pred <- matrix(runif(num_frag * dimension), nrow = num_frag, ncol = dimension)
  return(x_pred)
}

select_columns <- function(M, ind){
  return(M[,ind])
}

partial_ztz <- function(x) {
  x <- cbind(1, x)
  t(x) %*% x
}


partial_zty <- function(x, y) {
  x <- cbind(1, x)
  t(x) %*% y
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
