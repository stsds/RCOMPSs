row_range <- function(ind, nr, n){
  if(ind * nr <= n){
    return(( (ind - 1) * nr + 1 ):( ind * nr ))
  }else{
    return(( (ind - 1) * nr + 1 ):n)
  }
}

compute_ztz <- function(x, numrows, use_RCOMPSs) {
  partials <- list()
  i <- 1
  total_rows <- nrow(x)
  if(use_RCOMPSs){
    while( (i-1)*numrows < total_rows ) {
      block_x <- x[row_range(i, numrows, total_rows), , drop = FALSE]
      partials[[i]] <- task.partial_ztz(block_x)
      i <- i + 1
    }
  }else{
    while( (i-1)*numrows < total_rows ) {
      partials[[i]] <- partial_ztz(x[row_range(i, numrows, total_rows), , drop = FALSE])
      i <- i + 1
    }
  }
  if(use_RCOMPSs){
    #partials <- do.call(task.merge, partials)
    return(partials)
  }else{
    #partials <- do.call(merge, partials)
    return(partials)
  }
}

compute_zty <- function(x, y, numrows, use_RCOMPSs) {
  partials <- list()
  i <- 1
  total_rows <- nrow(x)
  if(use_RCOMPSs){
    while( (i-1)*numrows < total_rows ) {
      AAA <- x[row_range(i, numrows, total_rows), , drop = FALSE]
      BBB <- y[row_range(i, numrows, total_rows), , drop = FALSE]
      cat(paste0("DIIMENSION OF X: ", dim(AAA)[1], " x ", dim(AAA)[2], "\n"))
      cat(paste0("DIIMENSION OF Y: ", dim(BBB)[1], " x ", dim(BBB)[2], "\n"))
      partials[[i]] <- task.partial_zty(AAA, BBB)
      i <- i + 1
    }
  }else{
    while( (i-1)*numrows < total_rows ) {
      partials[[i]] <- partial_zty(x[row_range(i, numrows, total_rows), , drop = FALSE],
                                   y[row_range(i, numrows, total_rows), , drop = FALSE])
      i <- i + 1
    }
  }
  if(use_RCOMPSs){
    #partials <- do.call(task.merge, partials)
    return(partials)
  }else{
    #partials <- do.call(merge, partials)
    return(partials)
  }
}
