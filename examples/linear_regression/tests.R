args <- commandArgs(trailingOnly = TRUE)
use_RCOMPSs <- as.logical(args[1])

library(RCOMPSs)
source("tasks_linear_regression.R")
source("functions_linear_regression.R")

task.partial_ztz <- task(partial_ztz, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
task.partial_zty <- task(partial_zty, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
task.merge <- task(merge, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
task.merge3 <- task(merge3, "tasks_linear_regression.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)

n <- 100 
d <- 3

set.seed(2)
x0 <- x <- matrix(runif(n*d), nrow = n, ncol = d)
y0 <- y <- matrix(rnorm(n), nrow = n, ncol = 1)

fit_intercept <- TRUE
numrows <- 20
arity <- 2
if(use_RCOMPSs){
  compss_start()
}
#zty <- compute_zty(x, y, fit_intercept, numrows, arity, use_RCOMPSs)
#zty <- compss_wait_on(zty)
#cat("zty111\n")
#print(zty)
ztz1 <- compute_ztz(x,    fit_intercept, numrows, arity, use_RCOMPSs)
#cat("ztz111\n")
#print(ztz)
if(use_RCOMPSs){
  #compss_barrier()
}
cat("DIFFERENCE x:", sum((x0-x)^2), "\n")
cat("DIFFERENCE y:", sum((y0-y)^2), "\n")
cat("fit_interceptttttttt", fit_intercept, "\n")
if(use_RCOMPSs){
  #compss_barrier()
  #Sys.sleep(200)
}
zty1 <- compute_zty(x0, y0, TRUE, numrows, arity, use_RCOMPSs)
#ztz2 <- compute_ztz(x,    fit_intercept, numrows, arity, use_RCOMPSs)
#zty2 <- compute_zty(x0, y0, fit_intercept, numrows, arity, use_RCOMPSs)
#cat("zty222\n")
#print(zty)
if(use_RCOMPSs){
  ztz1_res <- compss_wait_on(ztz1)
  #ztz2 <- compss_wait_on(ztz2)
  zty1_res <- compss_wait_on(zty1)
  #zty2 <- compss_wait_on(zty2)
  compss_stop()
}
cat("ztz1\n")
print(ztz1_res)
#cat("ztz2\n")
#print(ztz2)
cat("zty1\n")
print(zty1_res)
#cat("zty2\n")
#print(zty2)

