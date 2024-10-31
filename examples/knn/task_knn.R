KNN_frag <- function(train, test, cl, k){
  res_dist <- fields::rdist(test, train)
  res_cl <- t(apply(res_dist, 1, function(x) cl[sort(x, index.return = TRUE)$ix[1:k]]))
  res_dist <- t(apply(res_dist, 1, function(x) sort(x)[1:k]))
  return(list(res_dist, res_cl))
}

KNN_merge <- function(...){
  k <- ncol(list(...)[[1]][[1]])
  res_dist <- do.call(cbind, lapply(list(...), function(x) x[[1]]))
  res_cl <- do.call(cbind, lapply(list(...), function(x) x[[2]]))
  ntest <- nrow(res_dist)
  sorted_distance_ind <- t(apply(res_dist, 1, function(x) sort(x, index.return = TRUE)$ix[1:k]))
  y_pred <- numeric(ntest)
  for(j in 1:ntest){
    ## Get the Mode
    x <- res_cl[j,sorted_distance_ind[j,]]
    ux <- unique(x)
    y_pred[j] <- ux[which.max(tabulate(match(x, ux)))]
  }
  return(y_pred)
}
