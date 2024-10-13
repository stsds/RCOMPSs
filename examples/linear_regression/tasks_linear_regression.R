DEBUG <- list(
  partial_ztz = FALSE,
  partial_zty = FALSE,
  compute_model_parameters = FALSE,
  merge = TRUE
)

partial_ztz <- function(x, fit_intercept) {
  if (fit_intercept) {
    x <- cbind(1, x)
  }
  t(x) %*% x
}


partial_zty <- function(x, y, fit_intercept) {
  if (fit_intercept) {
    x <- cbind(1, x)
  }
  t(x) %*% y
}


compute_model_parameters <- function(ztz, zty, fit_intercept) {
  params <- solve(ztz, zty)
  if (fit_intercept) {
    return(list(params[1], params[-1]))
  } else {
    return(list(rep(0, ncol(zty)), params))
  }
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
      cat("Input dimensionnnnnnnnn", i, dim(input[[i]]), "\n")
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
