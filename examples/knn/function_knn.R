Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

KNN <- function(train, test, cl, k, num_frag, use_RCOMPSs = FALSE){
  ntrain_frag <- c(0, cumsum(rep(nrow(train) / num_frag, num_frag)))
  RES <- list()
  for(i in 1:num_frag){
    #cat("i in KNN", i, "\n")
    train_ind <- (ntrain_frag[i]+1):ntrain_frag[i+1]
    if(use_RCOMPSs){
      RES[[i]] <- task.KNN_frag(train[train_ind,], test, cl[train_ind], k)
    }else{
      RES[[i]] <- KNN_frag(train[train_ind,], test, cl[train_ind], k)
    }
  }
  # print(RES)
  #cat("length of RES:", length(RES), "\n")
  if(use_RCOMPSs){
    y_pred <- do.call(task.KNN_merge, RES)
  }else{
    y_pred <- do.call(KNN_merge, RES)
  }
  return(y_pred)
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
  exp_num_points_train <- 1000
  exp_num_points_test <- 200
  dimensions <- 2
  num_class <- 5
  fragments <- 4
  k <- 3
  arity <- 2

  # Execution using RCOMPSs
  use_RCOMPSs <- FALSE

  # Execution using default R function
  use_R_default <- FALSE

  # asking for help
  is.asking_for_help <- FALSE

  # Confusion matrix?
  confusion_matrix <- TRUE

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
        exp_num_points_train <- as.integer(args[i + 1])
      } else if (args[i] == "--n_train") {
        exp_num_points_train <- as.integer(args[i + 1])
      } else if (args[i] == "-N"){
        exp_num_points_test <- as.integer(args[i + 1])
      } else if (args[i] == "--n_test") {
        exp_num_points_test <- as.integer(args[i + 1])
      } else if (args[i] == "-d") {
        dimensions <- as.integer(args[i + 1])
      } else if (args[i] == "--dimensions") {
        dimensions <- as.integer(args[i + 1])
      } else if (args[i] == "-c") {
        num_class <- as.integer(args[i + 1])
      } else if (args[i] == "--num_class") {
        num_class <- as.integer(args[i + 1])
      } else if (args[i] == "-f") {
        fragments <- as.integer(args[i + 1])
      } else if (args[i] == "--fragments") {
        fragments <- as.integer(args[i + 1])
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
    cat("  -n, --n_train <exp_num_points_train>      Number of training points\n")
    cat("  -N, --n_test <exp_num_points_test>        Number of testing points\n")
    cat("  -d, --dimensions <dimensions>             Number of dimensions\n")
    cat("  -c, --num_class <num_class>               Number of classes\n")
    cat("  -f, --fragments <fragments>               Number of fragments\n")
    cat("  -k, --knn <k>                             Number of the nearest neighbours to consider\n")
    cat("  -a, --arity <arity>                       Reduction arity\n")
    cat("  -p, --plot <needs_plot>                   Boolean: Plot?\n")
    cat("  -m, --confusion_matrix <confusion_matrix> Flag: confusion_matrix?\n")
    cat("  -C, --RCOMPSs <use_RCOMPSs>               Flag: Use RCOMPSs parallelization?\n")
    cat("  -R, --R-default <use_R_default>           Flag: Use default knn function to compute?\n")
    cat("  -h, --help                                Show this help message\n")
    q(status = 0)
  }

  #if(numpoints %% fragments){
  #  stop("Number of fragment is not a factor of number of points!\n")
  #}

  return(list(
              seed = seed,
              exp_num_points_train = exp_num_points_train,
              exp_num_points_test = exp_num_points_test,
              dimensions = dimensions,
              num_class = num_class,
              num_fragments = fragments,
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
  cat(sprintf("  Number of training points: %d\n", params$exp_num_points_train))
  cat(sprintf("  Number of testing points: %d\n", params$exp_num_points_test))
  cat(sprintf("  Dimensions: %d\n", params$dimensions))
  cat(sprintf("  Number of class: %d\n", params$num_class))
  cat(sprintf("  Number of fragments: %d\n", params$num_fragments))
  cat(sprintf("  K: %d\n", params$k))
  cat(sprintf("  Arity: %d\n", params$arity))
  cat("  confusion_matrix:", params$confusion_matrix, "\n")
  cat("  use_RCOMPSs:", params$use_RCOMPSs, "\n")
  cat("  use_R_default:", params$use_R_default, "\n")
}
