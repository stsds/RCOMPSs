library(ggplot2)

# Set the true parameters
true_mean <- 5
true_sd <- 2
n_samples <- 10000  # Number of samples

# Parallel execution of multiple chains
n_chains <- 50
n_iter <- 50000
proposal_sd <- 0.5
burnout <- 1000

# Generate synthetic data
set.seed(123)
MCinput <- list()
MCinput[[1]] <- rnorm(n_samples, mean = true_mean, sd = true_sd)
MCinput[[2]] <- mean(MCinput[[1]])  # Start with the sample mean
MCinput[[3]] <- n_iter
MCinput[[4]] <- proposal_sd
MCinput[[5]] <- true_sd
MCinput[[6]] <- burnout

# Time functions
tic <- function() {
  tic_start <<- base::Sys.time()
}
toc <- function(package_name) {
  dt <- base::difftime(base::Sys.time(), tic_start)
  dt <- round(dt, digits = 1L)
  message(paste0(package_name, ": Elapsed time: "), format(dt))
}

# Plotting function
MCplot <- function(all_samples, true_mean, package_name) {
  pdf(paste0("MCMC_samples_", package_name, ".pdf"))
  p <- ggplot(data.frame(all_samples), aes(x = all_samples)) +
  geom_histogram(bins = 30, fill = "blue", alpha = 0.7) +
  geom_vline(xintercept = true_mean, color = "red", linetype = "dashed") +
  labs(title = "MCMC Samples from Normal Distribution (Parallel)",
       x = "Sampled Mean", y = "Frequency") +
  theme_minimal()
  print(p)
  dev.off()
}
