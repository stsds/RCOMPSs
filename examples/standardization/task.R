get_mean <- function(x){
  mean(x)
}
get_sd <- function(x){
  sd(x)
}
standardize <- function(x, mu, sigma){
  (x - mu) / sigma
}

