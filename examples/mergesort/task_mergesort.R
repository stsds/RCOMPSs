merge <- function(left, right) {
  len_left <- length(left)
  len_right <- length(right)
  result <- numeric(len_left + len_right)
  
  i <- 1
  j <- 1
  k <- 1
  
  while (i <= len_left && j <= len_right) {
    if (left[i] <= right[j]) {
      result[k] <- left[i]
      i <- i + 1
    } else {
      result[k] <- right[j]
      j <- j + 1
    }
    k <- k + 1
  }
  
  while (i <= len_left) {
    result[k] <- left[i]
    i <- i + 1
    k <- k + 1
  }
  
  while (j <= len_right) {
    result[k] <- right[j]
    j <- j + 1
    k <- k + 1
  }
  
  return(result)
}