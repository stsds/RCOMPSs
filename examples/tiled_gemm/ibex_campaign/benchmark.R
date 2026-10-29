library(RCOMPSs)
root<-Sys.getenv("CAMPAIGN_ROOT");source(file.path(root,"tasks.R"))
compss_start()
main<-function(){
 on.exit(compss_stop(),add=TRUE)
 n<-as.integer(Sys.getenv("CASE_N","8192"));g<-as.integer(Sys.getenv("CASE_GPUS","1"))
 cores<-as.integer(Sys.getenv("CASE_CPUS","62"));mode<-Sys.getenv("CASE_MODE","hybrid")
 out<-Sys.getenv("CASE_OUTPUT");tile<-as.integer(Sys.getenv("CASE_TILE","2048"))
 cpu<-task(campaign_cpu,"tasks.R",return_value=TRUE)
 collect<-function(job)as.data.frame(compss_wait_on(job)$summary,stringsAsFactors=FALSE)
 gpu<-task(constraint(campaign_gpu,processors=list(
  list(processorType="CPU",computingUnits="1"),list(processorType="GPU",computingUnits="1"))),
  "tasks.R",return_value=TRUE)
 if(mode=="resident"){
  f<-task(constraint(campaign_resident,processors=list(
   list(processorType="CPU",computingUnits="1"),list(processorType="GPU",computingUnits="1"))),
   "tasks.R",return_value=TRUE)
  write.csv(as.data.frame(compss_wait_on(f(n))),out,row.names=FALSE)
  return(invisible(NULL))
 }
 if(mode=="probe"){
  stopifnot(g>0)
  for(round in 1:3){
   jobs<-lapply(seq_len(g),function(i)gpu(512L,0L,128L,0L,128L,128L,TRUE))
   rows<-do.call(rbind,lapply(jobs,collect))
   stopifnot(length(unique(rows$bus))==g,all(rows$error<1e-10))
   write.csv(rows,paste0(out,"-",round,".csv"),row.names=FALSE)
  }
  return(invisible(NULL))
 }
 if(mode=="calibrate"){
  samples<-list()
  for(i in 0:3){
   samples[[length(samples)+1]]<-collect(cpu(4096L,0L,64L,0L,1024L,1024L))
   samples[[length(samples)+1]]<-collect(gpu(8192L,0L,4096L,0L,4096L,2048L))
  }
  z<-do.call(rbind,samples);write.csv(z,out,row.names=FALSE);return(invisible(NULL))
 }
 # Rate-based static partition; calibration is independent of reported cases.
 cpu_rate<-as.double(Sys.getenv("CPU_RATE"));gpu_rate<-as.double(Sys.getenv("GPU_RATE"))
 cpu_share<-if(g==0)1 else max(0,cores-g)*cpu_rate/(max(0,cores-g)*cpu_rate+g*gpu_rate)
 work<-campaign_regions(n,cpu_share,g)
 jobs<-list();begin<-as.numeric(Sys.time())
 # Submit both resource classes in interleaved output-region order.
 for(q in seq_len(nrow(work))){
  w<-work[q,];f<-if(w$gpu)gpu else cpu
  jobs[[length(jobs)+1]]<-f(n,as.integer(w$row),as.integer(w$rows),as.integer(w$col),as.integer(w$cols),tile)
 }
 C<-matrix(0,n,n);summaries<-vector("list",length(jobs))
 for(q in seq_along(jobs)){
  value<-compss_wait_on(jobs[[q]]);s<-as.data.frame(value$summary)
  stopifnot(identical(dim(value$C),c(as.integer(s$rows),as.integer(s$cols))))
  C[seq.int(s$row+1L,s$row+s$rows),seq.int(s$col+1L,s$col+s$cols)]<-value$C
  summaries[[q]]<-s;rm(value);jobs[q]<-list(NULL)
 }
 z<-do.call(rbind,summaries);finish<-as.numeric(Sys.time())
 # Full output is materialized as an ordinary R matrix on the master.
 if(n<=512L){
  campaign_helpers()
  reference<-.51*(campaign_input(n,0L,n,0L,n,1L)%*%campaign_input(n,0L,n,0L,n,2L))-
    .42*campaign_input(n,0L,n,0L,n,3L)
  stopifnot(max(abs(C-reference))<1e-10)
 }
 stopifnot(sum(z$flops)==2*as.double(n)^3,all(z$error<1e-10))
 if(g>0)stopifnot(length(unique(z$bus[z$gpu]))==g)
 write.csv(z,paste0(out,"-tasks.csv"),row.names=FALSE)
 write.csv(data.frame(n=n,gpus=g,cpus=cores,tile=tile,workflow_seconds=finish-begin,
  cpu_share=cpu_share,actual_cpu_share=sum(z$flops[!z$gpu])/sum(z$flops),
  tasks=nrow(z),gpu_tasks=sum(z$gpu),cpu_tasks=sum(!z$gpu),
  max_error=max(z$error)),out,row.names=FALSE)
}
main()
