args <- commandArgs(trailingOnly = TRUE)
use_RCOMPSs <- as.logical(args[1])

library(RCOMPSs)
source("tasks_tests2.R")
source("functions_tests2.R")

if(use_RCOMPSs){
  compss_start()
  task.partial_ztz <- task(partial_ztz, "tasks_tests2.R", info_only = FALSE, return_value = TRUE, DEBUG = TRUE)
  task.partial_zty <- task(partial_zty, "tasks_tests2.R", info_only = FALSE, return_value = TRUE, DEBUG = TRUE)
  #task.merge <- task(merge, "tasks_tests2.R", info_only = FALSE, return_value = TRUE, DEBUG = FALSE)
}

n <- 100 
d <- 3

set.seed(2)
x1 <- x <- matrix(runif(n*d), nrow = n, ncol = d)
y <- matrix(rnorm(n), nrow = n, ncol = 1)

numrows <- 75

#execution_pipe <- c("B", "B", "A", "B", "B")
#execution_pipe <- c("A", "B", "B")
execution_pipe <- c("B", "A", "B", "A")

RESULTS <- list()
for(i in 1:length(execution_pipe)){
  if(execution_pipe[i] == "A"){
    RESULTS[[i]] <- compute_ztz(x,    numrows, use_RCOMPSs)
  }else if(execution_pipe[i] == "B"){
    RESULTS[[i]] <- compute_zty(x, y, numrows, use_RCOMPSs)
  }else{
    stop("Wrong type!")
  }
  if(use_RCOMPSs) compss_barrier()
}
if(use_RCOMPSs){
  for(j in 1:length(execution_pipe)){
    RESULTS[[j]] <- compss_wait_on(RESULTS[[j]])
  }
  compss_stop()
}
for(k in 1:length(execution_pipe)){
  cat(execution_pipe[k], "\n")
  print(RESULTS[[k]])
}
