library(RCOMPSs);source('resident_tasks.R');set.seed(631);n<-8192L
A<-matrix(runif(n*n)-.5,n,n);B<-matrix(runif(n*n)-.5,n,n);C<-matrix(runif(n*n)-.5,n,n)
rows<-list()
for(trial in 0:3)for(tile in if(trial%%2==0)c(512L,1024L,2048L)else c(2048L,1024L,512L)){
 gc();t<-proc.time()[['elapsed']];z<-gemm_pipeline(A,B,C,tile,1L,TRUE);seconds<-proc.time()[['elapsed']]-t
 row<-data.frame(tile=tile,trial=trial,seconds=seconds);rows[[length(rows)+1]]<-row;print(row);write.csv(do.call(rbind,rows),'native.csv',row.names=FALSE)
}
RCOMPSs.DeleteRunContext('gemm_pipeline')
