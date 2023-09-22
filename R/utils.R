#' task
#'
#' This function is the decorator for tasks.
#'
#' @param f The function to be executed.
#' @param ... Metadata.
#' @return The decorated function
#' @export
task <- function(f, ...){
  metadata <- list(...)
  f_name <- as.character(as.list(match.call())$f)
  function(...){
    arguments <- as.list(match.call(definition = f, expand.dots = FALSE))
    cat("The name of f is:", f_name, "\n")
    decor_f_name <- arguments[[1]]
    cat("The name of the decorated function is:", decor_f_name, "\n")
    arguments[[1]] <- NULL
    if(length(arguments) > 0){
      cat("The arguments f receives are:\n")
      print(arguments)
    }
    if(length(metadata) > 0){
      cat("Metadata:\n")
      print(metadata)
    }
    
    # Do not execute function f, invoke instead the runtime with the arg and the information
    
    # Call register function here
    register_core_element(CESignature = f_name,
                          ImplSignature = f_name,
                          ImplConstraints = "",
                          ImplType = "METHOD",
                          ImplLocal = "False",
                          ImplIO = "False",
                          prolog = c("", "", "False"),
                          epilog = c("", "", "False"),
                          container = c("", "", ""),
                          typeArgs = c("filename", f_name))
    
    # Call execute_task here
  }
}
