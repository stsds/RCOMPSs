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
print_parameters(params)
attach(params)
if(!Minimize){
  cat("Done.\n")
}
# Finished processing parameters

if (use_RCOMPSs){
  require(RCOMPSs)

  compss_start()
  task.LR_fill_fragment <- task(LR_fill_fragment, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.LR_genpred <- task(LR_genpred, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  #task.select_columns <- task(select_columns, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.partial_ztz <- task(partial_ztz, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.partial_zty <- task(partial_zty, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.compute_model_parameters <- task(compute_model_parameters, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.compute_prediction <- task(compute_prediction, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.row_combine <- task(row_combine, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
  task.merge <- task(merge, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
}

# Example usage:
set.seed(seed)
n <- num_fit
N <- num_pred
d <- dimensions_x
D <- dimensions_y

# Generate random regression coefficients
true_coeff <- matrix(round(runif((d+1)*D, -10, 10)), nrow = d + 1, ncol = D)
## If all the covariate are corresponding to 0, we need to do it again
for(j in 1:D){
  while(all(true_coeff[-1,j] == 0)){
    true_coeff[-1,j] <- round(runif(d, -10, 10))
  }
}

for(replicate in 1:1){
  cat("Doing replicate", replicate, "...\n")

  if(replicate > 1) compare_accuracy <- FALSE

  start_time <- proc.time()

  # Generate random data
  X_Y <- vector("list", num_fragments_fit)
  PRED <- vector("list", num_fragments_pred)
  if(use_RCOMPSs){
    params <- list(dim = c(n / num_fragments_fit, d, D))
    for(i in 1:num_fragments_fit){
      X_Y[[i]] <- task.LR_fill_fragment(params, true_coeff)
    }
    params <- list(n = N / num_fragments_pred, d = d)
    for(j in 1:num_fragments_pred){
      PRED[[j]] <- task.LR_genpred(params)
    }
  }else{
    params <- list(dim = c(n / num_fragments_fit, d, D))
    for(i in 1:num_fragments_fit){
      X_Y[[i]] <- LR_fill_fragment(params, true_coeff)
    }
    params <- list(n = N / num_fragments_pred, d = d)
    for(j in 1:num_fragments_pred){
      PRED[[j]] <- LR_genpred(params)
    }
  }

  # Fit the model
  model <- fit_linear_regression(X_Y, d, D, arity = arity, use_RCOMPSs = use_RCOMPSs)

  # Predict using the model
  predictions <- predict_linear_regression(PRED, model, arity, use_RCOMPSs)

  if(use_RCOMPSs){
    predictions <- compss_wait_on(predictions)
  }
  linear_regression_time <- proc.time()

  LR_time <- round(linear_regression_time[3] - start_time[3], 3)

  # To compare accuracy
  if(compare_accuracy){
    if(use_RCOMPSs){
      X_Y <- do.call(task.row_combine, X_Y)
      X_Y <- compss_wait_on(X_Y)
      PRED <- do.call(task.row_combine, PRED)
      PRED <- compss_wait_on(PRED)
      predictions <- do.call(task.row_combine, predictions)
      predictions <- compss_wait_on(predictions)
      model <- compss_wait_on(model)
    }else{
      X_Y <- do.call(rbind, X_Y)
      PRED <- do.call(rbind, PRED)
      predictions <- do.call(rbind, predictions)
    }
    X <- X_Y[,1:dimensions_x]
    Y <- X_Y[,(dimensions_x+1):(dimensions_x+dimensions_y)]
    start_lm <- proc.time()
    model_base <- lm(Y ~ X)
    coeff <- coefficients(model_base)
    #predictions_base <- predict(model, PRED)
    #predictions_base <- coeff[1] + apply(t(coeff[2:length(coeff)] * t(PRED)), MARGIN = 1, FUN = sum)
    predictions_base <- cbind(1, PRED) %*% coeff
    end_lm <- proc.time()
    lm_time <- round(end_lm[3] - start_lm[3], 3)
    # Results:
    cat("True coefficients:\n"); print(round(true_coeff, 2))
    cat("Estimated coefficients:\n"); print(round(model, 2))
    cat("`lm` coefficients:\n"); print(round(coeff, 2))
    cat("Squared error of the difference between `predictions` and `predictions_base` is:", sum((predictions - predictions_base)^2), "\n")

    rm(X, Y, PRED, model_base, coeff, predictions_base)
  }

  cat("-----------------------------------------\n")
  cat("-------------- RESULTS ------------------\n")
  cat("-----------------------------------------\n")
  cat("Linear regression time:", LR_time, "seconds\n")
  if(compare_accuracy) cat("Base R lm time:", lm_time, "seconds\n")
  cat("-----------------------------------------\n")
  cat("LR_RES,seed,num_fit,num_pred,dimensions_x,dimensions_y,num_fragments_fit,num_fragments_pred,arity,needs_plot,use_RCOMPSs,compare_accuracy,Minimize,LR_time,run\n")
  cat(paste0("LR_res,", seed, ",", num_fit, ",", num_pred, ",", dimensions_x, ",", dimensions_y, ",", num_fragments_fit, ",", num_fragments_pred, ",", arity, ",", needs_plot, ",", use_RCOMPSs, ",", compare_accuracy, ",", Minimize, ",", LR_time, ",", replicate, "\n"))

  rm(X_Y, model, predictions)
}

if(use_RCOMPSs) compss_stop()
