DEBUG <- list(
  partial_sum = FALSE,
  merge = FALSE,
  converged = FALSE,
  recompute_centres = FALSE,
  kmeans_frag = FALSE
)

fill_fragment <- function(params_fill_fragment){

  centres <- params_fill_fragment[[1]]
  n <- params_fill_fragment[[2]]
  mode <- params_fill_fragment[[3]]
  frag_id <- params_fill_fragment[[4]]

  # Obtain necessary numbers
  ncluster <- nrow(centres)
  dim <- ncol(centres)

  # Random generation distributions
  rand <- list(
               "normal" = function(k) rnorm(k, mean = 0, sd = 0.05),
               "uniform" = function(k) runif(k, 0, 0.1)
  )

  # Initialize the random points
  frag <- matrix(NA, nrow = n, ncol = dim + 1)
  frag[, 1:dim] <- matrix(rand[[mode]](n * dim), nrow = n, ncol = dim)

  # Assign to different groups
  group_ind <- sample(1:ncluster, n, replace = TRUE)
  frag[, 1:dim] <- frag[, 1:dim] + centres[group_ind, ]
  frag[, dim+1] <- frag_id

  return(frag)
}

partial_sum <- function(fragment, centres) {
  #partial_sum <- function(params_partial_sum) {

  #fragment <- as.matrix(params_partial_sum[[1]])
  #centres <- as.matrix(params_partial_sum[[2]])

  # Get necessary parameters
  ncl <- nrow(centres)
  if(ncol(fragment) != ncol(centres)) {
    stop("fragment and centres must have the same number of columns\nNow fragment has <", ncol(fragment), "> columns and centres has <", ncol(centres), "> columns\n", sep = "")
  }else{
    dimension <- ncol(fragment)
  }
  if(DEBUG$partial_sum) {
    cat("Doing partial sum\n")
    cat("nrow(centres) =", nrow(centres), "\n")
    cat(paste0("dimension = ", dimension, "\n"))
    cat(paste0("typeof(fragment) = ", typeof(fragment), "; ", "typeof(centres) = ", typeof(centres), "\n"))
    cat("fragment:\n")
    #rint(fragment)
    cat("centres:\n")
    print(centres)
  }

  partials <- matrix(nrow = ncl, ncol = dimension + 1)
  if(DEBUG$partial_sum) {
    cat("partials in partial_sum after initialization (should be full of NAs)\n")
    print(partials)
  }
  close_centres <- apply(proxy::dist(fragment, centres, method = "euclidean"), 1, which.min)

  if(DEBUG$partial_sum) {
    cat("close_centres\n")
    print(close_centres)
  }
  for (center_idx in 1:ncl) {
    if(DEBUG$partial_sum) {
      cat("center_idx =", center_idx, "\n")
    }
    indices <- which(close_centres == center_idx)
    if(DEBUG$partial_sum) {
      cat("indices:", indices, "\n")
      cat("fragment[indices, ]\n")
      print(fragment[indices, ])
    }
    # Check if there is any empty cluster
    if(length(indices) == 0){
      partials[center_idx,] <- 0
    }else if(length(indices) == 1){
      partials[center_idx, 1:dimension] <- fragment[indices, ]
      partials[center_idx, dimension + 1] <- 1
    }else{
      if(DEBUG$partial_sum) {
        cat("colSums:", "\n")
        print(colSums(fragment[indices, ]))
        cat("length(indices):", "\n")
        print(length(indices))
      }
      partials[center_idx, 1:dimension] <- colSums(fragment[indices, ])
      partials[center_idx, dimension + 1] <- length(indices)
    }
  }
  if(DEBUG$partial_sum) {
    cat("partials in partial_sum after computation\n")
    print(partials)
  }
  return(partials)
}

merge2 <- function(partial1, partial2) {
  if(DEBUG$merge) {
    cat("Doing merge2\n")
    print(partial1)
    print(partial2)
  }
  accum <- partial1 + partial2
  if(DEBUG$merge) {
    cat("accum\n")
    print(accum)
  }
  return(accum)
  # [COR1 COR2 COR3] NUM_POINTS
}

merge <- function(...){
  input <- list(...)
  input_len <- length(input)
  if(DEBUG$merge) {
    cat("Doing merge\n")
    for(i in 1:input_len){
      cat("Input", i, "\n")
      print(input[[i]])
    }
  }
  if(input_len == 1){
    return(input[[1]])
  }else if(input_len >= 2){
    accum <- input[[1]]
    for(i in 2:input_len){
      accum <- accum + input[[i]]
    }
    if(DEBUG$merge) {
      cat("accum\n")
      print(accum)
    }
    return(accum)
  }else{
    stop("Wrong input in `merge`!\n")
  }
  # [COR1 COR2 COR3] NUM_POINTS
}
