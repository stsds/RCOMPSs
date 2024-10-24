library(class)
library(data.table)
library(ggplot2)

source("task_knn.R")
source("function_knn.R")

iseed <- 2
num_class <- 5
dimension <- 2
exp_num_points_train <- 100
exp_num_points_test <- 20
k <- 3
nf <- 4

set.seed(iseed)
num_points_train <- rep(round(exp_num_points_train / num_class), num_class - 1)
num_points_train[num_class] <- exp_num_points_train - sum(num_points_train)
num_points_train <- c(0, num_points_train)
num_points_test <- rep(round(exp_num_points_test / num_class), num_class - 1)
num_points_test[num_class] <- exp_num_points_test - sum(num_points_test)
num_points_test <- c(0, num_points_test)
x_train <- matrix(nrow = exp_num_points_train, ncol = dimension)
y_train <- numeric(exp_num_points_train)
x_test <- matrix(nrow = exp_num_points_test, ncol = dimension)
y_test <- numeric(exp_num_points_test)

# Generate data
for(i in 2:(num_class+1)){
  center <- runif(dimension, min = -10, max = 10)
  ind_train <- (sum(num_points_train[1:(i-1)]) + 1):sum(num_points_train[1:i])
  x_train[ind_train,] <- MASS::mvrnorm(n = num_points_train[i], mu = center, Sigma = diag(dimension))
  y_train[ind_train] <- i-1
  ind_test <- (sum(num_points_test[1:(i-1)]) + 1):sum(num_points_test[1:i])
  x_test[ind_test,] <- MASS::mvrnorm(n = num_points_test[i], mu = center, Sigma = diag(dimension)*5)
  y_test[ind_test] <- i-1
}
y_train <- factor(y_train)
y_test <- factor(y_test)

y_pred <- numeric(exp_num_points_test)

ggplot() +
  geom_point(aes(x = x_train[,1], y = x_train[,2], 
                 colour = y_train,
                 shape = "Training data"), size = 3) +
  geom_point(aes(x = x_test[,1], y = x_test[,2], 
                 shape = "Testing data"))

res_KNN <- KNN(train = x_train, test = x_test, cl = y_train, k = k, num_frag = nf)
print(res_KNN)

res_knn <- knn(train = x_train, test = x_test, cl = y_train, k = k)
print(res_knn)