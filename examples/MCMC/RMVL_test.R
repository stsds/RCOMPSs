n_samples <- 1000000  # Number of samples

# Generate synthetic data
set.seed(123)
dat <- rnorm(n_samples, mean = 1, sd = 1)

compss_serialize <- function(object, filepath) {
  con <- RMVL::mvl_open(filepath, append = TRUE, create = TRUE)
  RMVL::mvl_write_object(con, object, name = "obj")
  RMVL::mvl_close(con)
}
compss_unserialize <- function(filepath) {
  con <- RMVL::mvl_open(filepath)
  object <- RMVL::mvl2R(con$obj)
  RMVL::mvl_close(con)
  return(object)
}

compss_serialize(dat, "normal_data")
d <- compss_unserialize("normal_data")
print(d)
