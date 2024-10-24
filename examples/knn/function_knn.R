Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

KNN <- function(train, test, cl, k, num_frag){
  ntrain_frag <- c(0, cumsum(rep(nrow(train) / num_frag, num_frag)))
  RES <- list()
  for(i in 1:num_frag){
    cat("i in KNN", i, "\n")
    train_ind <- (ntrain_frag[i]+1):ntrain_frag[i+1]
    RES[[i]] <- KNN_frag(train[train_ind,], test,
             cl[train_ind], k)
  }
  # print(RES)
  cat("length of RES:", length(RES), "\n")
  y_pred <- do.call(KNN_merge, RES)
  return(y_pred)
}