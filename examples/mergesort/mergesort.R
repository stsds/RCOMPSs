#!/usr/bin/env Rscript

mergesort <- function(array) {
  if (length(array) <= 1) {
    return(array)
  }
  
  mid <- floor(length(array) / 2)
  left <- array[1:mid]
  right <- array[(mid + 1):length(array)]
  
  left_sorted <- mergesort(left)
  right_sorted <- mergesort(right)
  
  merged_array <- task.merge(left_sorted, right_sorted)
  
  return(merged_array)
}


library(RCOMPSs)
compss_start()

source("task_mergesort.R")
task.merge <- task(merge, "task_mergesort.R", info_only=FALSE, DEBUG=FALSE, return_value=TRUE)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
	stop("Error:Usage: Rscript mergesort.R <n> <seed>")
}

n <- as.integer(args[1])
seed <- as.integer(args[2])

if (is.na(n) || n <= 0 || is.na(seed)) {
	stop("Error: n must be > 0 and both must be integers.")
}

set.seed(seed)

synthetic_array <- sample(1:1000, n, replace = TRUE)
futue_object <- mergesort(synthetic_array)
result <- compss_wait_on(futue_object)
print(result)

compss_stop()

