args <- commandArgs(trailingOnly = TRUE)

library(RCOMPSs)

source("task_knn.R")
source("function_knn.R")

params <- parse_arguments(FALSE)
attach(params)

set.seed(seed)
num_points_train <- rep(round(exp_num_points_train / num_class), num_class - 1)
num_points_train[num_class] <- exp_num_points_train - sum(num_points_train)
num_points_train <- c(0, num_points_train)
num_points_test <- rep(round(exp_num_points_test / num_class), num_class - 1)
num_points_test[num_class] <- exp_num_points_test - sum(num_points_test)
num_points_test <- c(0, num_points_test)
x_train <- matrix(nrow = exp_num_points_train, ncol = dimensions)
y_train <- numeric(exp_num_points_train)
x_test <- matrix(nrow = exp_num_points_test, ncol = dimensions)
y_test <- numeric(exp_num_points_test)


if(use_RCOMPSs){
  compss_start()
  task.KNN_frag <- task(KNN_frag, "task_knn.R", return_value = TRUE, DEBUG = TRUE)
  task.KNN_merge <- task(KNN_merge, "task_knn.R", return_value = TRUE, DEBUG = TRUE)
}

# Generate data
for(i in 2:(num_class+1)){
  center <- runif(dimensions, min = -10, max = 10)
  ind_train <- (sum(num_points_train[1:(i-1)]) + 1):sum(num_points_train[1:i])
  x_train[ind_train,] <- MASS::mvrnorm(n = num_points_train[i], mu = center, Sigma = diag(dimensions))
  y_train[ind_train] <- i-1
  ind_test <- (sum(num_points_test[1:(i-1)]) + 1):sum(num_points_test[1:i])
  x_test[ind_test,] <- MASS::mvrnorm(n = num_points_test[i], mu = center, Sigma = diag(dimensions)*5)
  y_test[ind_test] <- i-1
}
y_train <- factor(y_train)
y_test <- factor(y_test)
#y_train <- as.character(y_train)
#y_test <- as.character(y_test)

y_pred <- numeric(exp_num_points_test)

library(ggplot2)
ggplot() +
  geom_point(aes(x = x_train[,1], y = x_train[,2], 
                 colour = y_train,
                 shape = "Training data"), size = 3) +
geom_point(aes(x = x_test[,1], y = x_test[,2], 
               shape = "Testing data"))

res_KNN <- KNN(train = x_train, test = x_test, cl = y_train, k = k, num_frag = num_fragments, use_RCOMPSs)
if(use_RCOMPSs){
  res_KNN <- compss_wait_on(res_KNN)
  compss_stop()
}
res_KNN <- as.factor(as.numeric(res_KNN))
if(confusion_matrix){
  cm <- caret::confusionMatrix(data = res_KNN, reference = y_test)
  print(cm)
}else{
  print(res_KNN)
}

if(use_R_default){
  res_knn <- class::knn(train = x_train, test = x_test, cl = y_train, k = k)
  if(confusion_matrix){
    cm <- caret::confusionMatrix(data = res_knn, reference = y_test)
    print(cm)
  }else{
    print(res_knn)
  }
  if(!identical(res_knn, res_KNN)){
    cat("+++++++++++++++++++++++++++++++++++")
    cat("\n\033[31;1;4mWrong result!\n\033[0m")
  }else{
    cat("+++++++++++++++++++++++++++++++++++")
    cat("\n\033[32;1;4mCorrect result!\n\033[0m")
  }
}
