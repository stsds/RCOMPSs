fit_linear_regression <- function(x, y, fit_intercept = TRUE) {
  if (inherits(x, "Matrix") || inherits(y, "Matrix")) {
    stop("Sparse data is not supported.")
  }
  
  n_features <- ncol(x)
  n_targets <- ncol(y)
  ztz <- compute_ztz(x, fit_intercept)
  zty <- compute_zty(x, y, fit_intercept)
  params <- compute_model_parameters(ztz, zty, fit_intercept)
  
  list(intercept = params[[1]], coef = params[[2]], n_features = n_features, n_targets = n_targets)
}

predict_linear_regression <- function(model, x) {
  if (inherits(x, "Matrix")) {
    stop("Sparse data is not supported.")
  }
  
  return(as.matrix(x) %*% model$coef + model$intercept)
}

save_model <- function(model, filepath) {
  saveRDS(model, file = filepath)
}

load_model <- function(filepath) {
  readRDS(file = filepath)
}

compute_ztz <- function(x, fit_intercept) {
  partials <- list()
  for (i in seq_len(nrow(x))) {
    partials[[i]] <- partial_ztz(x[i, , drop = FALSE], fit_intercept)
  }
  Reduce(function(...) Reduce("+", list(...)), partials)
}

partial_ztz <- function(x, fit_intercept) {
  if (fit_intercept) {
    x <- cbind(1, x)
  }
  t(x) %*% x
}

compute_zty <- function(x, y, fit_intercept) {
  partials <- list()
  for (i in seq_len(nrow(x))) {
    partials[[i]] <- partial_zty(x[i, , drop = FALSE], y[i, , drop = FALSE], fit_intercept)
  }
  Reduce(function(...) Reduce("+", list(...)), partials)
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

# Example usage:
set.seed(1)
n <- 10; d <- 3
training_data_x <- matrix(runif(n*d), nrow = n, ncol = d)
training_data_y <- matrix(runif(n), nrow = n, ncol = 1)
test_data_x <- matrix(runif(n*d), nrow = n, ncol = d)
model <- fit_linear_regression(training_data_x, training_data_y)
predictions <- predict_linear_regression(model, test_data_x)
save_model(model, "model.rds")
loaded_model <- load_model("model.rds")
