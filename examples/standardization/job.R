library(RCOMPSs)
source("task.R")
X <- runif(100) + 10
compss_start()
get_mean.dec <- task(get_mean, "task.R", 
                    info_only = F, return_value = T)
get_sd.dec <- task(get_sd, "task.R", 
                  info_only = F, return_value = T)
standardize.dec <- task(standardize, "task.R",
                       info_only = F, return_value = T)
# Task (1)
mu <- get_mean.dec(X)
# Task (2)
sigma <- get_sd.dec(X)
# Task (3)
X_standardized <- standardize.dec(X, mu, sigma)
# Get the result
X_standardized <- compss_wait_on(X_standardized)
compss_stop()
