partial_ztz <- function(x) {
  t(x) %*% x
}

partial_zty <- function(x, y) {
  #cat("ztyyyyyyyyyyy")
  #cat("xxxxxxxxxxxxxxx")
  #print(x)
  #cat("yyyyyyyyyyyyyyy")
  #print(y)
  cat(paste0("DIMENSION OF X: ", dim(x)[1], " x ", dim(x)[2], "\n"))
  cat(paste0("DIMENSION OF Y: ", dim(y)[1], " x ", dim(y)[2], "\n"))
  RES <- t(x) %*% y
  #print("RESSSSSSSSSSSSSSSSSSSs")
  #print(RES)
  return(RES)
}

merge <- function(...){
  input <- list(...)
  input_len <- length(input)
  #cat("mergeeeeeeeeeeeeee\n")
  #print(input)

  if(input_len == 1){
    return(input[[1]])
  }else if(input_len >= 2){
    accum <- input[[1]]
    for(i in 2:input_len){
      accum <- accum + input[[i]]
    }
    return(accum)
  }else{
    stop("Wrong input in `merge`!\n")
  }
}
