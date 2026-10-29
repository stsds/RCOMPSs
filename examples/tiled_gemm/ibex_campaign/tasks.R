campaign_helpers <- function() {
  if (!exists("campaign_input", envir=.GlobalEnv, inherits=FALSE))
    Rcpp::sourceCpp(file.path(Sys.getenv("CAMPAIGN_ROOT"),"inputs.cpp"),
                    cacheDir=file.path(Sys.getenv("CAMPAIGN_ROOT"),"cpp-cache"),
                    rebuild=FALSE, env=.GlobalEnv)
}

campaign_block <- function(n,row,rows,col,cols,tile,gpu,probe=FALSE) {
  body_start<-as.numeric(Sys.time())
  campaign_helpers()
  device <- list(ordinal=-1L,bus="CPU")
  if(gpu) {
    assigned <- as.integer(strsplit(Sys.getenv("COMPSS_BINDED_GPUS"),",")[[1]][1])
    device <- campaign_device(assigned,Sys.getenv("CAMPAIGN_GPUS"))
    name <- "campaign_task"
    RCOMPSs::RCOMPSs.CreateRunContext(name)
    RCOMPSs::RCOMPSs.SetOperationPlacement(name,"GPU")
    RCOMPSs::RCOMPSs.SetRunMode(name,"async")
    RCOMPSs::RCOMPSs.SetOperationContext(name)
    on.exit(RCOMPSs::RCOMPSs.DeleteRunContext(name),add=TRUE)
  }
  kk <- split(seq_len(n)-1L,(seq_len(n)-1L)%/%tile)
  a <- lapply(kk,function(k)campaign_input(n,row,rows,k[1],length(k),1L))
  b <- lapply(kk,function(k)campaign_input(n,k[1],length(k),col,cols,2L))
  c <- campaign_input(n,row,rows,col,cols,3L)
  start <- as.numeric(Sys.time())
  result <- RCOMPSs::rcompss_gemm_tile_reduce(a,b,c,.51,-.42,gpu)
  end <- as.numeric(Sys.time())
  error <- campaign_check(result,n,row,col)
  stopifnot(error<1e-10)
  # Hold simultaneous probe tasks long enough to observe distinct GPUs.
  if(probe) Sys.sleep(1)
  summary <- data.frame(row=row,rows=rows,col=col,cols=cols,gpu=gpu,
             ordinal=device$ordinal,bus=device$bus,pid=Sys.getpid(),
             cpu_mask=paste(campaign_affinity(),collapse=";"),
             start=start,end=end,seconds=end-start,error=error,
             flops=2*as.double(n)*rows*cols)
  rm(a,b,c);gc()
  summary$body_seconds<-as.numeric(Sys.time())-body_start
  list(summary=summary,C=result)
}

campaign_cpu <- function(n,row,rows,col,cols,tile,probe=FALSE)
  campaign_block(n,row,rows,col,cols,tile,FALSE,probe)
campaign_gpu <- function(n,row,rows,col,cols,tile,probe=FALSE)
  campaign_block(n,row,rows,col,cols,tile,TRUE,probe)

# One separately labeled capacity demonstration; not a primary timing point.
campaign_resident <- function(n) {
  campaign_helpers()
  assigned<-as.integer(strsplit(Sys.getenv("COMPSS_BINDED_GPUS"),",")[[1]][1])
  info<-campaign_device(assigned,Sys.getenv("CAMPAIGN_GPUS"))
  name<-"resident_capacity";a<-b<-c<-NULL
  RCOMPSs::RCOMPSs.CreateRunContext(name)
  RCOMPSs::RCOMPSs.SetOperationPlacement(name,"GPU")
  RCOMPSs::RCOMPSs.SetRunMode(name,"async")
  RCOMPSs::RCOMPSs.SetOperationContext(name)
  on.exit({for(x in list(a,b,c))RCOMPSs::rcompss_gpu_matrix_release(x);RCOMPSs::RCOMPSs.DeleteRunContext(name)})
  tryCatch({
    A<-campaign_input(n,0L,n,0L,n,1L)
    B<-campaign_input(n,0L,n,0L,n,2L)
    C<-campaign_input(n,0L,n,0L,n,3L)
    start<-as.numeric(Sys.time())
    a<-RCOMPSs::rcompss_gpu_matrix_upload(A)
    b<-RCOMPSs::rcompss_gpu_matrix_upload(B)
    c<-RCOMPSs::rcompss_gpu_matrix_upload(C)
    RCOMPSs::rcompss_gpu_matrix_gemm(a,b,c,.51,-.42,2048L)
    result<-RCOMPSs::rcompss_gpu_matrix_download(c)
    seconds<-as.numeric(Sys.time())-start
    error<-campaign_check(result,n,0L,0L);stopifnot(error<1e-10)
    data.frame(n=n,success=TRUE,seconds=seconds,error=error,reason="",bus=info$bus)
  },error=function(e)data.frame(n=n,success=FALSE,seconds=NA_real_,error=NA_real_,
                               reason=conditionMessage(e),bus=info$bus))
}

campaign_regions <- function(n,cpu_share,g) {
  block<-min(4096L,max(1024L,as.integer(ceiling(n/4))))
  starts<-seq.int(0L,n-1L,by=block);regions<-expand.grid(row=starts,col=starts)
  work<-list();budget<-0
  for(q in seq_len(nrow(regions))){
    r<-regions$row[q];c<-regions$col[q];nr<-min(block,n-r);nc<-min(block,n-c)
    budget<-budget+nr*nc*cpu_share
    cr<-if(g==0)nr else min(nr,floor(budget/nc/64)*64)
    budget<-budget-cr*nc
    rb<-if(g==0)256L else 64L;cb<-if(g==0)2048L else 1024L
    if(cr>0)for(j in seq.int(c,c+nc-1L,by=cb))for(i in seq.int(r,r+cr-1L,by=rb))
      work[[length(work)+1]]<-data.frame(row=i,rows=min(rb,r+cr-i),col=j,cols=min(cb,c+nc-j),gpu=FALSE)
    if(cr<nr)work[[length(work)+1]]<-data.frame(row=r+cr,rows=nr-cr,col=c,cols=nc,gpu=TRUE)
  }
  do.call(rbind,work)
}
