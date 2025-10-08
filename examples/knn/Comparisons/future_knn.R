suppressPackageStartupMessages({
  library(future)
})

DEBUG <- list(
  KNN_fill_fragment = FALSE,
  KNN_frag = FALSE,
  KNN_merge = FALSE,
  KNN_classify = FALSE
)

KNN_fill_fragment <- function(params_fill_fragment){
  centres <- params_fill_fragment[[1]]
  n <- params_fill_fragment[[2]]
  nclass <- nrow(centres)
  dim <- ncol(centres)
  frag <- matrix(nrow = n, ncol = dim + 1)
  frag[,1:dim] <- matrix(rnorm(n * dim, sd = 0.1), nrow = n, ncol = dim)
  group_ind <- sample(1:nclass, n, replace = TRUE)
  frag[,dim + 1] <- as.integer(group_ind)
  frag[,1:dim] <- frag[,1:dim] + centres[group_ind, ]
  return(frag)
}

#KNN_frag <- function(train, test, k){
#  dimensions <- ncol(train) - 1
#  x_train <- train[,1:dimensions]
#  cl <- train[,dimensions+1]
#  x_test <- test[,1:dimensions]
#  res_dist <- fields::rdist(x_test, x_train)
#  res_cl <- t(apply(res_dist, 1, function(x) cl[order(x)[1:k]]))
#  res_dist <- t(apply(res_dist, 1, function(x) sort(x)[1:k]))
#  dist_cl <- cbind(res_dist, res_cl)
#  return(dist_cl)
#}

KNN_frag <- function(train, test, k){
  dimensions <- ncol(train) - 1
  x_train <- train[, 1:dimensions, drop = FALSE]
  cl      <- train[, dimensions + 1]
  x_test  <- test[, 1:dimensions, drop = FALSE]

  nn <- RANN::nn2(data = x_train, query = x_test, k = k, searchtype = "standard")

  # nn$nn.dists and nn$nn.idx are already n_test x k matrices
  res_dist <- nn$nn.dists
  idx_mat  <- nn$nn.idx

  # map indices to class labels without apply
  res_cl <- matrix(cl[as.vector(idx_mat)], nrow = nrow(idx_mat), ncol = ncol(idx_mat))
  dist_cl <- cbind(res_dist, res_cl)
  T3 <- proc.time()[3]

  return(dist_cl)
}

KNN_merge <- function(...){
  input <- list(...)
  input_len <- length(input)
  if(input_len == 1){
    return(input[[1]])
  }else{
    k <- ncol(input[[1]]) / 2
    res_dist <- do.call(cbind, lapply(input, function(x) x[,1:k]))
    res_cl <- do.call(cbind, lapply(input, function(x) x[,(k+1):(2*k)]))
    ntest <- nrow(res_dist)
    sorted_distance_ind <- t(apply(res_dist, 1, function(d) order(d)[1:k]))
    res_dist <- matrix(res_dist[cbind(1:ntest, c(sorted_distance_ind))], nrow = ntest, ncol = k)
    res_cl <- matrix(res_cl[cbind(1:ntest, c(sorted_distance_ind))], nrow = ntest, ncol = k)
    dist_cl <- cbind(res_dist, res_cl)
    return(dist_cl)
  }
}

KNN_classify <- function(...){
  input <- list(...)
  if(length(input) > 1){
    final_merge <- do.call(KNN_merge, list(...))
  }else{
    final_merge <- input[[1]]
  }
  k <- ncol(final_merge) / 2
  final_cl <- final_merge[,(k+1):(2*k)]
  KNN_get_mode <- function(x) {
    ux <- unique(x)
    ux[which.max(tabulate(match(x, ux)))]
  }
  predictions <- apply(final_cl, 1, KNN_get_mode)
  return(predictions)
}

######################################################################################
######################################################################################
### Process arguments
parse_arguments <- function(Minimize) {

  if(!Minimize){
    cat("Starting parse_arguments\n")
  }

  args <- commandArgs(trailingOnly = TRUE)

  # Define default values
  # Note that if `num_fragments` is not a factor of `numpoints`, the last fragment may give NA due to lack of points.
  seed <- 1
  n_train <- 1000
  n_test <- 200
  dimensions <- 2
  num_class <- 5
  fragments_train <- 5
  fragments_test <- 5
  k <- 3
  arity <- 2
  replicates <- 1

  # asking for help
  is.asking_for_help <- FALSE

  # Confusion matrix?
  confusion_matrix <- FALSE

  # plot?
  needs_plot <- FALSE

  # Parse arguments
for (i in seq_along(args)) {
    val <- args[i + 1]
    switch(args[i],
      "-s" =, "--seed" = { seed <- as.integer(val) },
      "-n" =, "--n_train" = { n_train <- as.integer(val) },
      "-N" =, "--n_test" = { n_test <- as.integer(val) },
      "-d" =, "--dimensions" = { dimensions <- as.integer(val) },
      "-c" =, "--num_class" = { num_class <- as.integer(val) },
      "-f" =, "--fragments_train" = { fragments_train <- as.integer(val) },
      "-F" =, "--fragments_test" = { fragments_test <- as.integer(val) },
      "-k" =, "--knn" = { k <- as.integer(val) },
      "-a" =, "--arity" = { arity <- as.integer(val) },
      "-m" =, "--confusion_matrix" = { confusion_matrix <- TRUE },
      "-p" =, "--plot" = { needs_plot <- as.logical(val) },
      "-r" =, "--replicates" = { replicates <- as.integer(val) },
              "--ncores" = { ncores <- as.integer(val) },
      "-h" =, "--help" = { is.asking_for_help <- TRUE }
    )
  }

  if(is.asking_for_help){
    cat("Usage: Rscript knn.R [options]\n")
    cat("Options:\n")
    cat("  -s, --seed <seed>                         Seed for random number generator\n")
    cat("  -n, --n_train <n_train>                   Number of training points\n")
    cat("  -N, --n_test <n_test>                     Number of testing points\n")
    cat("  -d, --dimensions <dimensions>             Number of dimensions\n")
    cat("  -c, --num_class <num_class>               Number of classes\n")
    cat("  -f, --fragments_train <fragments_train>   Number of fragments of training data\n")
    cat("  -F, --fragments_test  <fragments_test>    Number of fragments of testing data\n")
    cat("  -k, --knn <k>                             Number of the nearest neighbours to consider\n")
    cat("  -a, --arity <arity>                       Reduction arity\n")
    cat("  -p, --plot <needs_plot>                   Boolean: Plot?\n")
    cat("  -m, --confusion_matrix <confusion_matrix> Flag: confusion_matrix?\n")
    cat("  -r, --replicates <replicates>             Number of replicates\n")
    cat("  --ncores <ncores>                         Number of cores to use\n")
    cat("  -h, --help                                Show this help message\n")
    q(status = 0)
  }

  if(n_train %% fragments_train != 0){
    stop("Number of fragment_train is not a factor of n_train!\n")
  }

  if(n_test %% fragments_test != 0){
    stop("Number of fragment_test is not a factor of n_test!\n")
  }

  return(list(
              seed = seed,
              n_train = n_train,
              n_test = n_test,
              dimensions = dimensions,
              num_class = num_class,
              num_fragments_train = fragments_train,
              num_fragments_test = fragments_test,
              k = k,
              arity = arity,
              confusion_matrix = confusion_matrix,
              needs_plot = needs_plot,
              replicates = replicates,
              ncores = ncores
              ))
}

print_parameters <- function(params) {
  cat("Parameters:\n")
  cat("  Seed:", params$seed, "\n")
  cat("  Number of training points:", params$n_train, "\n")
  cat("  Number of testing points:", params$n_test, "\n")
  cat("  Dimensions:", params$dimensions, "\n")
  cat("  Number of class:", params$num_class, "\n")
  cat("  Number of fragments of training data:", params$num_fragments_train, "\n")
  cat("  Number of fragments of testing data:", params$num_fragments_test, "\n")
  cat("  K:", params$k, "\n")
  cat("  Arity:", params$arity, "\n")
  cat("  confusion_matrix:", params$confusion_matrix, "\n")
  cat("  needs_plot:", params$needs_plot, "\n")
  cat("  Replicates:", params$replicates, "\n")
}

args <- commandArgs(trailingOnly = TRUE)

Minimize <- FALSE
# Parse arguments
if(length(args) >= 1){
  for (i in 1:length(args)) {
    if (args[i] == "-M" || args[i] == "--Minimize") Minimize <- TRUE
  }
}

if(!Minimize){
  cat("Getting parameters ... ")
}
params <- parse_arguments(Minimize)
if(!Minimize){
  print_parameters(params)
}
attach(params)
if(!Minimize){
  cat("Done.\n")
}

set.seed(seed)
options(future.globals.maxSize = Inf)
plan(multicore, workers = ncores)

for(replicate in 1:replicates){

  start_time <- proc.time()

  if(!Minimize){
    cat("Generating data replicate", replicate, "... ")
  }

  points_per_fragment_train <- max(1, n_train %/% num_fragments_train)
  points_per_fragment_test <- max(1, n_test %/% num_fragments_test)
  true_centres <- matrix(runif(num_class * dimensions), nrow = num_class, ncol = dimensions)
  params_train <- list(centres = true_centres, n = points_per_fragment_train)
  params_test <- list(centres = true_centres, n = points_per_fragment_test)


  # Parallel data generation using future
  x_train <- vector("list", num_fragments_train)
  x_train_future <- vector("list", num_fragments_train)
  for(f in seq_len(num_fragments_train)){
    x_train_future[[f]] <- future({
      set.seed(seed + f)
      KNN_fill_fragment(params_train)
    }, seed = NULL)
  }
  x_test <- vector("list", num_fragments_test)
  x_test_future <- vector("list", num_fragments_test)
  for(f in seq_len(num_fragments_test)){
    x_test_future[[f]] <- future({
      set.seed(seed + f)
      KNN_fill_fragment(params_test)
    }, seed = NULL)
  }

  initialization_time <- proc.time()
  if(!Minimize){
    cat("Done.\n")
  }

  # Parallel KNN computation using future for each task
  res_KNN_future <- vector("list", num_fragments_test)
  x_train <- value(x_train_future)
  #for(i in seq_len(num_fragments_test)) {
  #  cat("Processing test fragment", i, "\n")
  #  if("Future" %in% class(x_test_future[[i]])){
  #    x_test[[i]] <- value(x_test_future[[i]])
  #  }
  #  #res_KNN_future[[i]] <- vector("list", num_fragments_train)
  #  res_KNN_future[[i]] <- lapply(seq_len(num_fragments_train), function(j) {
  #    future({
  #      KNN_frag(x_train[[j]], x_test[[i]], k)
  #    })
  #  })
  #}
  #x_test <- value(x_test_future)
  res_KNN_future <- lapply(seq_len(num_fragments_test), function(i) {
    #cat("Processing test fragment", i, "\n")
    if("Future" %in% class(x_test_future[[i]])){
      x_test[[i]] <- value(x_test_future[[i]])
    }
    lapply(seq_len(num_fragments_train), function(j) {
      #cat("  with train fragment", j, "\n")
      future({
        KNN_frag(x_train[[j]], x_test[[i]], k)
      })
    })
  })

  if(!needs_plot) rm(x_train_future, x_train)  # Free memory if no plot is needed
  if(!needs_plot && !confusion_matrix) rm(x_test_future, x_test)   # Free memory if no plot is needed

  res_KNN <- vector("list", num_fragments_test)
  RES <- vector("list", num_fragments_test)
  for(i in seq_len(num_fragments_test)) {
    res_KNN[[i]] <- lapply(res_KNN_future[[i]], function(x){
      if("Future" %in% class(x)){
        value(x)
      }
    })
    while(length(res_KNN[[i]]) > arity){
      RES_subset <- res_KNN[[i]][1:arity]
      res_KNN[[i]] <- res_KNN[[i]][(arity + 1):length(res_KNN[[i]])]
      merge_future <- future({
        do.call(KNN_merge, RES_subset)
      })
      res_KNN[[i]][[length(res_KNN[[i]]) + 1]] <- value(merge_future)
    }
    # KNN_classify task
    RES[[i]] <- future({
        do.call(KNN_classify, res_KNN[[i]])
      })
  }
  res_KNN <- value(RES)
  rm(RES)
  if(needs_plot || confusion_matrix) PRED <- unlist(res_KNN)

  knn_time <- proc.time()

  Initialization_time <- initialization_time[3] - start_time[3]
  KNN_time <- knn_time[3] - initialization_time[3]
  Total_time <- proc.time()[3] - start_time[3]
  Initialization_time <- round(Initialization_time, 3)
  KNN_time <- round(KNN_time, 3)
  Total_time <- round(Total_time, 3)
  cat("-----------------------------------------\n")
  cat("-------------- RESULTS ------------------\n")
  cat("-----------------------------------------\n")
  cat("Initialization time:", Initialization_time, "seconds\n")
  cat("KNN time:", KNN_time, "seconds\n")
  cat("Total time:", Total_time, "seconds\n")
  cat("-----------------------------------------\n")
  if(Minimize){
    cat(paste0("KNN_RES_FUTURE,", seed, ",", n_train, ",", n_test, ",", dimensions, ",", num_class, ",", k, ",", arity, ",", num_fragments_train, ",", num_fragments_test, ",", confusion_matrix, ",", needs_plot, ",", Minimize, ",", Initialization_time, ",", KNN_time, ",", Total_time, ",", replicate, "\n"))
  }
  if(confusion_matrix){
    PRED <- as.factor(as.numeric(PRED))
    cat("Confusion Matrix:\n")
    x_test_mat <- do.call(rbind, x_test)
    cm <- caret::confusionMatrix(data = PRED, reference = as.factor(x_test_mat[,ncol(x_test_mat)]))
    print(cm)
  }
  cat("-----------------------------------------\n")

  if(needs_plot){
    library(ggplot2)
    x_train_mat <- do.call(rbind, x_train)
    class <- as.factor(x_train_mat[,dimensions + 1])
    x <- x_train_mat[,1]
    y <- x_train_mat[,2]
    p <- ggplot() +
      geom_point(aes(x = x, y = y, colour = class, shape = "Training data"), size = 3) +
      geom_point(aes(x = do.call(rbind, x_test)[,1], y = do.call(rbind, x_test)[,2], color = PRED, shape = "Testing data"))
    ggsave("future_plot_knn.pdf", plot = p, device = "pdf", width = 8, height = 8)
  }
}
