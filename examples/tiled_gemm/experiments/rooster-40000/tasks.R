gemm_large_case<-function(n,tiles){
 source('/home/abdullsm/software/rcompss-20261029/gemm-40000-worker-local/reduce_tasks.R')
 set.seed(631);cat('Generating inputs inside GPU task\n');flush.console()
 A<-matrix(runif(as.double(n)*n)-.5,n,n);B<-matrix(runif(as.double(n)*n)-.5,n,n);C<-matrix(runif(as.double(n)*n)-.5,n,n)
 columns<-sort(sample.int(n,8));reference<-.51*(A%*%B[,columns,drop=FALSE])-.42*C[,columns,drop=FALSE]
 rows<-list()
 for(tile in tiles){
  kk<-split(seq_len(n),(seq_len(n)-1L)%/%tile)
  at<-lapply(kk,function(k)A[,k,drop=FALSE]);bt<-lapply(kk,function(k)B[k,,drop=FALSE]);gc()
  for(trial in 0:3){
   cat('START',tile,trial,'\n');flush.console();t<-proc.time()[['elapsed']]
   result<-tile_gemm_gpu_reduce(at,bt,C,.51,-.42)
   seconds<-proc.time()[['elapsed']]-t
   error<-sqrt(sum((result[,columns,drop=FALSE]-reference)^2))/sqrt(sum(reference^2));stopifnot(error<1e-12)
   row<-data.frame(n=n,tile=tile,trial=trial,seconds=seconds,error=error,checked_columns=paste(columns,collapse=';'));print(row);flush.console()
   rows[[length(rows)+1]]<-row;write.csv(do.call(rbind,rows),'worker-results.csv',row.names=FALSE);rm(result);gc()
  }
  rm(at,bt);gc()
 }
 do.call(rbind,rows)
}
