# Processing parameters
args <- commandArgs(trailingOnly = TRUE)

Minimize <- FALSE
# Parse arguments
if(length(args) >= 1){
  for (i in 1:length(args)) {
    if (args[i] == "-M") {
      Minimize <- TRUE
    } else if (args[i] == "--Minimize") {
      Minimize <- TRUE
    }
  }
}

# Source necessary functions
if(!Minimize){
  cat("Sourcing necessary functions ... ")
}
source("tasks_linear_regression.R")
source("functions_linear_regression.R")
if(!Minimize){
  cat("Done.\n")
}

if(!Minimize){
  cat("Getting parameters ... ")
}
params <- parse_arguments(Minimize)
if(!Minimize){
  print_parameters(params)
}
attach(params)
if(!Minimize){
  cat("Done.\n")
}
# Finished processing parameters

if (use_RCOMPSs){
  require(RCOMPSs)

  task.partial_ztz <- task(partial_ztz, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.partial_zty <- task(partial_zty, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  #task.compute_model_parameters <- task(compute_model_parameters, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.merge <- task(merge, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.merge3 <- task(merge3, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
}

if (use_RCOMPSs){
  compss_start()
}

# Example usage:
set.seed(seed)
n <- numpoints
d <- dimensions

# Generate random data
training_data_x <- matrix(runif(n*d), nrow = n, ncol = d)

# Generate random regression coefficients
true_coeff <- numeric(d+1)
## If all the covariate are corresponding to 0, we need to do it again
while(sum(true_coeff) == true_coeff[1]){
  true_coeff <- round(runif(d+1, -10, 10))
}
## Create the response variable with some noise
training_data_y <- matrix(apply(t(true_coeff[2:(d+1)] * t(training_data_x)), 1, sum) + rnorm(n, mean = true_coeff[1], sd = 1), ncol = 1)
## Generate random data for prediction
test_data_x <- matrix(runif(n*d), nrow = n, ncol = d)

# Fit the model
model <- fit_linear_regression(training_data_x, 
                               training_data_y, 
                               fit_intercept = TRUE, 
                               numrows = numrows, 
                               arity = arity, 
                               use_RCOMPSs = use_RCOMPSs)

# Predict using the model
predictions <- predict_linear_regression(model, test_data_x)

# To compare accuracy
model_base <- lm(training_data_y ~ training_data_x)
coeff <- coefficients(model_base)
predictions_base <- coeff[1] + apply(t(coeff[2:length(coeff)] * t(test_data_x)), MARGIN = 1, FUN = sum)

# Results:
cat("True coefficients:     ", round(true_coeff, 2), "\n")
cat("Estimated coefficients:", round(c(model$intercept, model$coef), 2), "\n")
cat("`lm` coefficients:     ", round(coeff, 2), "\n")
cat("Squared error of the difference between `predictions` and `predictions_base` is:", sum((predictions - predictions_base)^2), "\n")
# save_model(model, "model.rds")
# loaded_model <- load_model("model.rds")

if (use_RCOMPSs){
  compss_stop()
}
