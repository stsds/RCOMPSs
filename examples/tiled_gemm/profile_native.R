library(RCOMPSs)
RCOMPSs.CreateRunContext('profile');RCOMPSs.SetOperationPlacement('profile','GPU');RCOMPSs.SetOperationContext('profile');RCOMPSs.SetRunMode('profile','async')
n<-4096L;b<-1024L;set.seed(40)
A<-matrix(runif(n*n)-.5,n,n);B<-matrix(runif(n*n)-.5,n,n);C<-matrix(runif(n*n)-.5,n,n)
kk<-split(seq_len(n),(seq_len(n)-1L)%/%b)
at<-lapply(kk,function(k)A[,k,drop=FALSE]);bt<-lapply(kk,function(k)B[k,,drop=FALSE])
reference<-.51*(A%*%B)-.42*C
rows<-list()
for(mode in c('CPU','GPU')) for(i in 0:3) {
 gc();t<-proc.time()[['elapsed']]
 result<-rcompss_gemm_tile_reduce(at,bt,C,.51,-.42,gpu=mode=='GPU')
 seconds<-proc.time()[['elapsed']]-t
 stopifnot(max(abs(result-reference))<1e-11)
 rows[[length(rows)+1]]<-data.frame(mode=mode,trial=i,seconds=seconds)
}
for(i in 1:3){p<-tempfile();t<-proc.time()[['elapsed']];compss_serialize(list(A=at,B=bt,C=C),p,'cpp');w<-proc.time()[['elapsed']]-t;t<-proc.time()[['elapsed']];payload<-compss_unserialize(p);r<-proc.time()[['elapsed']]-t;cat('SERIALIZE',w,'READ',r,'BYTES',file.info(p)$size,'\n');unlink(p)}
print(do.call(rbind,rows));write.csv(do.call(rbind,rows),file=Sys.getenv('PROFILE_OUTPUT'),row.names=FALSE)
