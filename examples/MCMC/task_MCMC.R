# MCMC function
mcmc_metropolis <- function(arguments) {
  # Unpack arguments
  normal_data <- as.vector(arguments[[1]])
  current_value <- arguments[[2]]
  n_iter <- arguments[[3]]
  proposal_sd <- arguments[[4]]
  true_sd <- arguments[[5]]
  burnout <- arguments[[6]]
  

  samples <- numeric(n_iter)
  
  for (i in 1:n_iter) {
    #if(i %% 1e4 == 0) {
      # Print progress every 10000 iterations
    #  message(paste("Iteration", i, "of", n_iter))
    #}
    proposed_value <- rnorm(1, mean = current_value, sd = proposal_sd)
    
    current_likelihood <- sum(dnorm(normal_data, mean = current_value, sd = true_sd, log = TRUE))
    proposed_likelihood <- sum(dnorm(normal_data, mean = proposed_value, sd = true_sd, log = TRUE))

    acceptance_ratio <- exp(proposed_likelihood - current_likelihood)

    if (runif(1) < acceptance_ratio) {
      current_value <- proposed_value
    }

    samples[i] <- current_value
  }

  res <- samples[(burnout+1):n_iter]
  
  return(res)
}
