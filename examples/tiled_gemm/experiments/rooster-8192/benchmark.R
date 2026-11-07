library(RCOMPSs);source('resident_tasks.R');compss_start()
main<-function(){
 on.exit(compss_stop(),add=TRUE)
 fn<-task(constraint(gemm_pipeline,processors=list(list(processorType='CPU',computingUnits='1'),list(processorType='GPU',computingUnits='1'))),'resident_tasks.R',return_value=TRUE)
 n<-8192L;set.seed(631);A<-matrix(runif(n*n)-.5,n,n);B<-matrix(runif(n*n)-.5,n,n);C<-matrix(runif(n*n)-.5,n,n)
 reference<-.51*(A%*%B)-.42*C;rows<-list()
 for(trial in 0:3)for(tile in if(trial%%2==0)c(512L,1024L,2048L)else c(2048L,1024L,512L)){
 gc();t<-proc.time()[['elapsed']];actual<-compss_wait_on(fn(A,B,C,tile,1L,TRUE));seconds<-proc.time()[['elapsed']]-t
 error<-sqrt(sum((actual-reference)^2))/sqrt(sum(reference^2));stopifnot(error<1e-12)
 row<-data.frame(n=n,tile=tile,trial=trial,seconds=seconds,error=error);print(row);rows[[length(rows)+1]]<-row;write.csv(do.call(rbind,rows),'rcompss.csv',row.names=FALSE)
 }
}
main()
