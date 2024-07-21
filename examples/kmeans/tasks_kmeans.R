DEBUG <- list(
  partial_sum = FALSE,
  merge = FALSE,
  converged = FALSE,
  recompute_centres = 2,
  kmeans_frag = FALSE
)

partial_sum <- function(fragment, centres) {

  if(ncol(fragment) != ncol(centres)) {
    stop("fragment and centres must have the same number of columns\nNow fragment has <", ncol(fragment), "> columns and centres has <", ncol(centres), "> columns\n", sep = "")
  }else{
    dimension <- ncol(fragment)
  }
  if(DEBUG$partial_sum) {
    cat("Doing partial sum\n")
    cat("nrow(centres) =", nrow(centres), "\n")
    cat("fragment:\n")
    print(fragment)
    cat("centres:\n")
    print(centres)
  }
  partials <- matrix(nrow = nrow(centres), ncol = dimension + 1)
  if(DEBUG$partial_sum) {
    cat("partials\n")
    print(partials)
  }
  close_centres <- apply(proxy::dist(fragment, centres, method = "euclidean"), 1, which.min)
  if(DEBUG$partial_sum) {
    cat("close_centres\n")
    print(close_centres)
  }
  for (center_idx in 1:nrow(centres)) {
    if(DEBUG$partial_sum) {
      cat("center_idx =", center_idx, "\n")
    }
    indices <- which(close_centres == center_idx)
    if(DEBUG$partial_sum) {
      cat("indices:", indices, "\n")
      cat("fragment[indices, ]\n")
      print(fragment[indices, ])
    }
    if(length(indices) > 1) {
      if(DEBUG$partial_sum) {
        cat("colSums:", "\n")
        print(colSums(fragment[indices, ]))
        cat("length(indices):", "\n")
        print(length(indices))
      }
      partials[center_idx, 1:dimension] <- colSums(fragment[indices, ])
    }else if(length(indices) == 1) {
      partials[center_idx, 1:dimension] <- fragment[indices, ]
    }
    partials[center_idx, dimension + 1] <- length(indices)
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
