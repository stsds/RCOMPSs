args <- commandArgs(trailingOnly = TRUE)
use_RCOMPSs <- as.logical(args[1])

library(RCOMPSs)
source("tasks_linear_regression.R")
source("functions_linear_regression.R")

if(use_RCOMPSs){
  compss_start()
  task.partial_ztz <- task(partial_ztz, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = TRUE)
  task.partial_zty <- task(partial_zty, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = TRUE)
  task.merge <- task(merge, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = TRUE)
  task.merge3 <- task(merge3, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
}

n <- 100 
n2 <- 70
d <- 3
d2 <- 2

set.seed(2)
x0 <- x <- matrix(runif(n*d), nrow = n, ncol = d)
y0 <- y <- matrix(rnorm(n), nrow = n, ncol = 1)
x2 <- matrix(runif(n2*d2), nrow = n2, ncol = d2)
y2 <- matrix(rnorm(n2), nrow = n2, ncol = 1)

fit_intercept <- TRUE
numrows <- 10
arity <- 2

A1 <- compute_ztz(x,    fit_intercept, numrows, arity, use_RCOMPSs)
B1 <- compute_zty(x0, y0, TRUE, numrows, arity, use_RCOMPSs)
#A2 <- compute_ztz(x,    fit_intercept, numrows, arity, use_RCOMPSs)
B2 <- compute_zty(x0, y0, TRUE, numrows, arity, use_RCOMPSs)
A3 <- compute_ztz(x,    fit_intercept, numrows, arity, use_RCOMPSs)
B3 <- compute_zty(x0, y0, TRUE, numrows, arity, use_RCOMPSs)
#A4 <- compute_ztz(x,    fit_intercept, numrows, arity, use_RCOMPSs)
if(use_RCOMPSs){
  A1 <- compss_wait_on(A1)
  B1 <- compss_wait_on(B1)
  #A2 <- compss_wait_on(A2)
  B2 <- compss_wait_on(B2)
  A3 <- compss_wait_on(A3)
  B3 <- compss_wait_on(B3)
  #A4 <- compss_wait_on(A4)
  #B4 <- compss_wait_on(B4)
  compss_stop()
}
cat("A1\n"); print(A1)
cat("B1\n"); print(B1)
#cat("A2\n"); print(A2)
cat("B2\n"); print(B2)
cat("A3\n"); print(A3)
cat("B3\n"); print(B3)
#cat("A4\n"); print(A4)
