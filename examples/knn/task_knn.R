# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

# @file task_knn.R
# @brief This file contains the tasks of the KNN classification application
# @version 1.0
# @author Xiran Zhang
# @date 2025-04-28

DEBUG <- list(
              KNN_fill_fragment = FALSE,
              KNN_frag = FALSE,
              KNN_merge = FALSE,
              KNN_classify = FALSE
)

KNN_fill_fragment <- function(centres, n){

  # Obtain necessary numbers
  nclass <- nrow(centres)
  dim <- ncol(centres)

  # Initialize the random points
  frag <- matrix(nrow = n, ncol = dim + 1)
  frag[,1:dim] <- matrix(rnorm(n * dim, sd = 0.1), nrow = n, ncol = dim)

  # Assign to different groups
  group_ind <- sample(1:nclass, n, replace = TRUE)
  frag[,dim + 1] <- as.integer(group_ind)
  frag[,1:dim] <- frag[,1:dim] + centres[group_ind, ]

  return(frag)
}

KNN_frag <- function(train, test, k){
  dimensions <- ncol(train) - 1
  x_train <- train[, 1:dimensions, drop = FALSE]
  cl      <- train[, dimensions + 1]
  x_test  <- test[, 1:dimensions, drop = FALSE]
  if(DEBUG$KNN_frag){
    cat(paste0("Starting KNN_frag, k = ", k, ", dimensions = ", dimensions, "\n"))
    cat("x_train:\n"); print(x_train)
    cat("cl:\n"); print(cl)
    cat("x_test:\n"); print(x_test)
  }
  nn <- RANN::nn2(data = x_train, query = x_test, k = k, searchtype = "standard")
  #res_dist <- fields::rdist(x_test, x_train)
  if(DEBUG$KNN_frag){
    cat("res_dist1:\n"); print(res_dist)
  }
  #res_cl <- t(apply(res_dist, 1, function(x) cl[sort(x, index.return = TRUE)$ix[1:k]]))
  if(DEBUG$KNN_frag){
    cat("res_cl:\n"); print(res_cl)
  }
  #res_dist <- t(apply(res_dist, 1, function(x) sort(x)[1:k]))
  if(DEBUG$KNN_frag){
    cat("res_dist2:\n"); print(res_dist)
  }

  # nn$nn.dists and nn$nn.idx are already n_test x k matrices
  res_dist <- nn$nn.dists
  idx_mat  <- nn$nn.idx

  # map indices to class labels without apply
  res_cl <- matrix(cl[as.vector(idx_mat)], nrow = nrow(idx_mat), ncol = ncol(idx_mat))
  dist_cl <- cbind(res_dist, res_cl)
  return(dist_cl)
}

KNN_merge <- function(...){
  input <- list(...)
  input_len <- length(input)
  if(DEBUG$KNN_merge) {
    cat("Doing KNN_merge\n")
    for(i in 1:input_len){
      cat("Input", i, "\n")
      print(input[[i]])
    }
  }
  if(input_len == 1){
    return(input[[1]])
  }else{
    #k <- ncol(input[[1]][[1]])
    #res_dist <- do.call(cbind, lapply(input, function(x) x[[1]]))
    #res_cl <- do.call(cbind, lapply(input, function(x) x[[2]]))
    k <- ncol(input[[1]]) / 2
    res_dist <- do.call(cbind, lapply(input, function(x) x[,1:k]))
    res_cl <- do.call(cbind, lapply(input, function(x) x[,(k+1):(2*k)]))
    ntest <- nrow(res_dist)
    if(DEBUG$KNN_merge) {
      cat("Doing KNN_merge\n")
      cat("k =", k, "\n")
      cat("input_len of KNN_merge:", input_len, "\n")
      cat("typeof(res_dist):", typeof(res_dist), "\n")
      cat("class(res_dist):", class(res_dist), "\n")
      cat("dim(res_dist):", dim(res_dist), "\n")
      cat("res_dist before merge:\n"); print(res_dist)
      cat("res_cl before merge:\n"); print(res_cl)
    }
    sorted_distance_ind <- t(apply(res_dist, 1, function(d) sort(d, index.return = TRUE)$ix[1:k]))
    res_dist <- matrix(res_dist[cbind(1:ntest, c(sorted_distance_ind))], nrow = ntest, ncol = k)
    res_cl <- matrix(res_cl[cbind(1:ntest, c(sorted_distance_ind))], nrow = ntest, ncol = k)
    #merge_res <- list(res_dist = res_dist, res_cl = res_cl)
    dist_cl <- cbind(res_dist, res_cl)
    if(DEBUG$KNN_merge) {
      cat("sorted_distance_ind:\n")
      print(sorted_distance_ind)
      cat("res_dist after merge:\n")
      print(res_dist)
      cat("res_cl after merge:\n")
      print(res_cl)
      #cat("merge_res:\n")
      #print(merge_res)
      cat("dist_cl:\n")
      print(dist_cl)
    }
    #return(merge_res)
    return(dist_cl)
  }
}

KNN_classify <- function(...){
  input <- list(...)
  if(DEBUG$KNN_classify) {
    cat("Doing KNN_classify\n")
    print(input)
  }
  if(length(input) > 1){
    final_merge <- do.call(KNN_merge, list(...))
  }else{
    final_merge <- input[[1]]
  }
  if(DEBUG$KNN_classify) {
    cat("final_merge:\n"); print(final_merge)
  }
  k <- ncol(final_merge) / 2
  #final_cl <- final_merge$res_cl
  final_cl <- final_merge[,(k+1):(2*k)]
  KNN_get_mode <- function(x) {
    ux <- unique(x)
    ux[which.max(tabulate(match(x, ux)))]
  }
  predictions <- apply(final_cl, 1, KNN_get_mode)
  if(DEBUG$KNN_classify) {
    cat("predictions:\n"); print(predictions)
  }

  return(predictions)
}
