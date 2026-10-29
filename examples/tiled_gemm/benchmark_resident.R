library(RCOMPSs);source('resident_tasks.R');compss_start()
main<-function() {
 on.exit(compss_stop(),add=TRUE)
 fn<-task(constraint(gemm_pipeline,processors=list(
   list(processorType='CPU',computingUnits='1'),list(processorType='GPU',computingUnits='1'))),
   'resident_tasks.R',return_value=TRUE)
 rows<-list();set.seed(631)
 for(n in c(2048L,4096L)) {
  A<-matrix(runif(n*n)-.5,n,n);B<-matrix(runif(n*n)-.5,n,n);C<-matrix(runif(n*n)-.5,n,n)
  product<-A%*%B
  for(steps in c(1L,5L,10L)) {
   reference<-C
   for(i in seq_len(steps))reference<-.51*product-.42*reference
   for(trial in 0:3) for(resident in if(trial%%2==0)c(FALSE,TRUE)else c(TRUE,FALSE)) {
    gc();t<-proc.time()[['elapsed']]
    actual<-compss_wait_on(fn(A,B,C,1024L,steps,resident))
    seconds<-proc.time()[['elapsed']]-t
    error<-sqrt(sum((actual-reference)^2))/sqrt(sum(reference^2))
    stopifnot(identical(dim(actual),dim(reference)),error<1e-12)
    row<-data.frame(n=n,tile=1024,steps=steps,trial=trial,resident=resident,seconds=seconds,error=error)
    rows[[length(rows)+1]]<-row;print(row)
    write.csv(do.call(rbind,rows),Sys.getenv('RESIDENT_OUTPUT'),row.names=FALSE)
   }
  }
 }
}
main()
