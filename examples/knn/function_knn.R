KNN <- function(train, test, k, use_RCOMPSs = FALSE){
  num_frag_train <- length(train)
  num_frag_test <- length(test)

  RES <- vector("list", num_frag_test)
  if(use_RCOMPSs){
    for(i in 1:num_frag_test){
      RES[[i]] <- vector("list", num_frag_train)
      for(j in 1:num_frag_train){
        RES[[i]][[j]] <- task.KNN_frag(train[[j]], test[[i]], k)
      }
      while(length(RES[[i]]) > arity){
        RES_subset <- RES[[i]][1:arity]
        RES[[i]] <- RES[[i]][(arity + 1):length(RES[[i]])]
        RES[[i]][[length(RES[[i]]) + 1]] <- do.call(task.KNN_merge, RES_subset)
      }
      RES[[i]] <- do.call(task.KNN_classify, RES[[i]])
    }
    for(i in 1:num_frag_test) RES[[i]] <- compss_wait_on(RES[[i]])
  }else{
    for(i in 1:num_frag_test){
      RES[[i]] <- vector("list", num_frag_train)
      for(j in 1:num_frag_train){
        RES[[i]][[j]] <- KNN_frag(train[[j]], test[[i]], k)
      }
      while(length(RES[[i]]) > arity){
        RES_subset <- RES[[i]][1:arity]
        RES[[i]] <- RES[[i]][(arity + 1):length(RES[[i]])]
        RES[[i]][[length(RES[[i]]) + 1]] <- do.call(KNN_merge, RES_subset)
      }
      RES[[i]] <- do.call(KNN_classify, RES[[i]])
    }
  }

  PRED <- do.call(c, RES)
  return(PRED)
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

  # Execution using RCOMPSs
  use_RCOMPSs <- FALSE

  # Execution using default R function
  use_R_default <- FALSE

  # asking for help
  is.asking_for_help <- FALSE

  # Confusion matrix?
  confusion_matrix <- FALSE

  # plot?
  needs_plot <- FALSE

  # Parse arguments
  if(length(args) >= 1){
    for (i in 1:length(args)) {
      if (args[i] == "-s") {
        seed <- as.integer(args[i + 1])
      } else if (args[i] == "--seed") {
        seed <- as.integer(args[i + 1])
      } else if (args[i] == "-n") {
        n_train <- as.integer(args[i + 1])
      } else if (args[i] == "--n_train") {
        n_train <- as.integer(args[i + 1])
      } else if (args[i] == "-N"){
        n_test <- as.integer(args[i + 1])
      } else if (args[i] == "--n_test") {
        n_test <- as.integer(args[i + 1])
      } else if (args[i] == "-d") {
        dimensions <- as.integer(args[i + 1])
      } else if (args[i] == "--dimensions") {
        dimensions <- as.integer(args[i + 1])
      } else if (args[i] == "-c") {
        num_class <- as.integer(args[i + 1])
      } else if (args[i] == "--num_class") {
        num_class <- as.integer(args[i + 1])
      } else if (args[i] == "-f") {
        fragments_train <- as.integer(args[i + 1])
      } else if (args[i] == "--fragments_train") {
        fragments_train <- as.integer(args[i + 1])
      } else if (args[i] == "-F") {
        fragments_test <- as.integer(args[i + 1])
      } else if (args[i] == "--fragments_test") {
        fragments_test <- as.integer(args[i + 1])
      } else if (args[i] == "-k") {
        k <- as.integer(args[i + 1])
      } else if (args[i] == "--knn") {
        k <- as.integer(args[i + 1])
      } else if (args[i] == "-a") {
        arity <- as.integer(args[i + 1])
      } else if (args[i] == "--arity") {
        arity <- as.integer(args[i + 1])
      } else if (args[i] == "-m") {
        confusion_matrix <- TRUE
      } else if (args[i] == "--confusion_matrix") {
        confusion_matrix <- TRUE
      } else if (args[i] == "-p") {
        needs_plot <- as.logical(args[i + 1])
      } else if (args[i] == "--plot") {
        needs_plot <- as.logical(args[i + 1])
      } else if (args[i] == "-C") {
        use_RCOMPSs <- TRUE
      } else if (args[i] == "--RCOMPSs") {
        use_RCOMPSs <- TRUE
      } else if (args[i] == "-R") {
        use_R_default <- TRUE
      } else if (args[i] == "--R-default") {
        use_R_default <- TRUE
      } else if (args[i] == "-h") {
        is.asking_for_help <- TRUE
      } else if (args[i] == "--help") {
        is.asking_for_help <- TRUE
      }
    }
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
    cat("  -C, --RCOMPSs <use_RCOMPSs>               Flag: Use RCOMPSs parallelization?\n")
    cat("  -R, --R-default <use_R_default>           Flag: Use default knn function to compute?\n")
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
              use_RCOMPSs = use_RCOMPSs,
              use_R_default = use_R_default
              ))
}

print_parameters <- function(params) {
  cat("Parameters:\n")
  cat(sprintf("  Seed: %d\n", params$seed))
  cat(sprintf("  Number of training points: %d\n", params$n_train))
  cat(sprintf("  Number of testing points: %d\n", params$n_test))
  cat(sprintf("  Dimensions: %d\n", params$dimensions))
  cat(sprintf("  Number of class: %d\n", params$num_class))
  cat(sprintf("  Number of fragments of training data: %d\n", params$num_fragments_train))
  cat(sprintf("  Number of fragments of testing data: %d\n", params$num_fragments_test))
  cat(sprintf("  K: %d\n", params$k))
  cat(sprintf("  Arity: %d\n", params$arity))
  cat("  confusion_matrix:", params$confusion_matrix, "\n")
  cat("  needs_plot:", params$needs_plot, "\n")
  cat("  use_RCOMPSs:", params$use_RCOMPSs, "\n")
  cat("  use_R_default:", params$use_R_default, "\n")
}
