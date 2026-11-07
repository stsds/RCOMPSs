root<-Sys.getenv("CAMPAIGN_ROOT");source(file.path(root,"tasks.R"));campaign_helpers()
device<-campaign_device(0L,Sys.getenv("CAMPAIGN_GPUS"))
reserve<-1024^3;budget<-device$free_bytes-reserve;tile<-2048L
rows<-list()
for(resident in c(TRUE,FALSE)){
 maxn<-if(resident)sqrt(budget/24) else -tile+sqrt(tile^2+budget/8)
 # Actual allocation tests around the conservative analytical bound.
 sizes<-unique(pmax(256L,as.integer(floor(maxn/256)*256+c(-512,-256,0,256,512))))
 for(n in sizes){
  predicted<-if(resident)24*as.double(n)^2 else 8*(as.double(n)^2+2*as.double(n)*tile)
  if(predicted>device$free_bytes-reserve/2)next
  result<-campaign_allocate(n,tile,resident)
  row<-data.frame(n=n,mode=if(resident)"three_resident_matrices"else"full_C_streamed_AB",
    success=result$success,predicted_bytes=predicted,allocated_bytes=result$allocated_bytes,
    total_bytes=device$total_bytes,initial_free_bytes=device$free_bytes,reserve_bytes=reserve)
  rows[[length(rows)+1]]<-row
 }
}
write.csv(do.call(rbind,rows),Sys.getenv("CASE_OUTPUT"),row.names=FALSE)
