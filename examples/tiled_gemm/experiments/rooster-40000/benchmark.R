library(RCOMPSs);source('tasks.R');compss_start()
main<-function(){on.exit(compss_stop(),add=TRUE)
 fn<-task(constraint(gemm_large_case,processors=list(list(processorType='CPU',computingUnits='1'),list(processorType='GPU',computingUnits='1'))),'tasks.R',return_value=TRUE)
 result<-compss_wait_on(fn(40000L,c(2048L,4096L)));write.csv(result,'rcompss.csv',row.names=FALSE);print(result)
}
main()
