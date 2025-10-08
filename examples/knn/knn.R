# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

# @file knn.R
# @brief This file contains the tasks of the KNN classification application
# @version 1.0
# @author Xiran Zhang
# @date 2025-04-28

# This application requires two extra packages: caret, ggplot2

flush.console()
Sys.sleep(1)

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
source("task_knn.R")
source("function_knn.R")
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

set.seed(seed)

if(use_RCOMPSs){
  require(RCOMPSs)

  # Initiate COMPSs
  if(!Minimize){
    cat("Starting COMPSs ... ")
  }
  compss_start()
  cat("COMPSs started!")
  flush.console()
  if(!Minimize){
    cat("Done.\n")
  }

  # Define the tasks
  if(!Minimize){
    cat("Defining the tasks ... ")
  }
  task.KNN_fill_fragment <- task(KNN_fill_fragment, "task_knn.R", return_value = TRUE, DEBUG = FALSE)
  task.KNN_frag <- task(KNN_frag, "task_knn.R", return_value = TRUE, DEBUG = FALSE)
  task.KNN_merge <- task(KNN_merge, "task_knn.R", return_value = TRUE, DEBUG = FALSE)
  task.KNN_classify <- task(KNN_classify, "task_knn.R", return_value = TRUE, DEBUG = FALSE)
  if(!Minimize){
    cat("Done.\n")
  }
}else{
  if(!Minimize){
    cat("Sequencial execution without RCOMPSs!\n")
  }
}

for(replicate in 1:replicates){

  start_time <- proc.time()

  # Generate data
  if(!Minimize){
    cat("Generating data replicate", replicate, "... ")
  }

  points_per_fragment_train <- as.integer(max(1, n_train %/% num_fragments_train))
  points_per_fragment_test <- as.integer(max(1, n_test %/% num_fragments_test))
  # Generate cluster central points
  true_centres <- matrix(runif(num_class * dimensions),
                         nrow = num_class, ncol = dimensions)

  x_train <- vector("list", num_fragments_train)
  x_test <- vector("list", num_fragments_test)
  if(use_RCOMPSs){
    for(f in 1:num_fragments_train){
      x_train[[f]] <- task.KNN_fill_fragment(centres = true_centres, n = points_per_fragment_train)
    }
    for(f in 1:num_fragments_test){
      x_test[[f]] <- task.KNN_fill_fragment(centres = true_centres, n = points_per_fragment_test)
    }
  }else{
    for(f in 1:num_fragments_train){
      x_train[[f]] <- KNN_fill_fragment(centres = true_centres, n = points_per_fragment_train)
    }
    for(f in 1:num_fragments_test){
      x_test[[f]] <- KNN_fill_fragment(centres = true_centres, n = points_per_fragment_test)
    }
  }

  initialization_time <- proc.time()
  if(!Minimize){
    cat("Done.\n")
  }

  # Run KNN
  res_KNN <- KNN(train = x_train, test = x_test, k = k, use_RCOMPSs)

  if(!Minimize){
    if(use_RCOMPSs){
      res_KNN <- compss_wait_on(res_KNN)
    }
    PRED <- do.call(c, res_KNN)
  }else if(use_RCOMPSs){
    compss_barrier(FALSE)
  }

  knn_time <- proc.time()

  Initialization_time <- initialization_time[3] - start_time[3]
  KNN_time <- knn_time[3] - initialization_time[3]
  Total_time <- proc.time()[3] - start_time[3]

  Initialization_time <- round(Initialization_time, 3)
  KNN_time <- round(KNN_time, 3)
  Total_time <- round(Total_time, 3)
  cat("-----------------------------------------\n")
  cat("-------------- RESULTS ------------------\n")
  cat("-----------------------------------------\n")
  cat("Initialization time:", Initialization_time, "seconds\n")
  cat("KNN time:", KNN_time, "seconds\n")
  cat("Total time:", Total_time, "seconds\n")
  cat("-----------------------------------------\n")
  if(Minimize){
    if(use_RCOMPSs){
	    cat(paste0("KNN_RES_RCOMPSs,", seed, ",", n_train, ",", n_test, ",", dimensions, ",", num_class, ",", k, ",", arity, ",", num_fragments_train, ",", num_fragments_test, ",", confusion_matrix, ",", needs_plot, ",", Minimize, ",", Initialization_time, ",", KNN_time, ",", Total_time, ",", replicate, "\n"))
    }else{
      cat(paste0("KNN_RES_Sequential,", seed, ",", n_train, ",", n_test, ",", dimensions, ",", num_class, ",", k, ",", arity, ",", num_fragments_train, ",", num_fragments_test, ",", confusion_matrix, ",", needs_plot, ",", Minimize, ",", Initialization_time, ",", KNN_time, ",", Total_time, ",", replicate, "\n"))
    }
  }
  if(!Minimize){
    PRED <- as.factor(as.numeric(PRED))
    if(confusion_matrix){
      cat("Confusion Matrix:\n")
      if(use_RCOMPSs) x_test <- compss_wait_on(x_test)
      x_test <- do.call(rbind, x_test)
      cm <- caret::confusionMatrix(data = PRED, reference = as.factor(x_test[,ncol(x_test)]))
      print(cm)
    }else{
      cat("Result of KNN:\n")
      print(PRED)
    }
    cat("-----------------------------------------\n")
  }

  if(use_R_default){
    res_knn <- class::knn(train = x_train[,1:dimensions], test = x_test[,1:dimensions], cl = x_train[,dimensions], k = k)
    if(confusion_matrix){
      cm <- caret::confusionMatrix(data = res_knn, reference = as.factor(x_test[,ncol(x_test)]))
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

  # Plot the data
  if(needs_plot){
    x_train <- do.call(rbind, x_train)
    class <- as.factor(x_train[,dimensions + 1])
    x <- x_train[,1]
    y <- x_train[,2]
    library(ggplot2)
    p <- ggplot() +
      geom_point(aes(x = x, y = y, colour = class,
                     shape = "Training data"), size = 3) +
    geom_point(aes(x = x_test[,1], y = x_test[,2], color = PRED,
               shape = "Testing data"))
    ggsave("RCOMPSs_plot_knn.pdf", plot = p, device = "pdf", width = 8, height = 8)
  }

  rm(x_train, x_test, res_KNN)
  gc()
  Sys.sleep(2)
}
#if(use_RCOMPSs) compss_stop()
