args<-commandArgs(TRUE);root<-args[1];d<-read.csv(file.path(root,"summary.csv"))
out<-file.path(root,"figures");dir.create(out,showWarnings=FALSE)
colors<-c(rcompss="#0072B2",parsec="#D55E00");shapes<-c("1"=16,"2"=17,"4"=15)
line<-c("1"=1,"2"=2,"4"=3)
style<-function(){par(mar=c(3.5,4,1.8,.7),mgp=c(2.3,.7,0),las=1,cex=.85,bty="l",family="Helvetica")}
series<-function(z,x,y,scale=1,errors=FALSE){
 for(runtime in c("rcompss","parsec"))for(g in sort(unique(z$gpus))){
  v<-z[z$runtime==runtime&z$gpus==g,];v<-v[order(v[[x]]),];if(!nrow(v))next
  lines(v[[x]],v[[y]]/scale,type="b",col=colors[runtime],
        pch=shapes[as.character(g)]-if(runtime=="parsec")15 else 0,lty=line[as.character(g)])
  if(errors)arrows(v[[x]],v[[paste0(y,"_min")]]/scale,v[[x]],v[[paste0(y,"_max")]]/scale,
                  code=3,angle=90,length=.025,col=colors[runtime])
 }
}
z<-d[d$study=="size",]
pdf(file.path(out,"ibex_gemm_scaling.pdf"),width=7.1,height=3.2);style()
plot(range(z$n),range(z$wall_seconds_min,z$wall_seconds_max),type="n",log="y",
     xlab="Matrix dimension N (FP64, square)",ylab="Fresh-process completion time (s)")
series(z,"n","wall_seconds",errors=TRUE)
under<-z[z$active_gpus_min<z$gpus,]
if(nrow(under))text(under$n,under$wall_seconds,
  labels=paste0(under$active_gpus_min,"-",under$active_gpus_max,"/",under$gpus),pos=3,cex=.55)
limits<-read.csv(file.path(root,"results","allocation-probe","limits.csv"))
resident_tested<-max(limits$n[limits$mode=="three_resident_matrices"&limits$success])
abline(v=resident_tested,lty=3,col="gray50")
labels<-as.vector(outer(c("RCOMPSs","PaRSEC"),c("1 GPU","2 GPUs","4 GPUs"),paste))
legend("topleft",legend=labels,col=rep(colors,3),pch=as.vector(rbind(shapes,shapes-15)),lty=rep(line,each=2),
       cex=.72,bty="n",ncol=2)
mtext(paste(unique(z$cpus),"allocated physical CPU cores in every configuration"),side=3,line=.3,cex=.75)
dev.off()
z<-d[d$study=="cpu",]
pdf(file.path(out,"ibex_gemm_cpu_threads.pdf"),width=7.1,height=3.2);par(mfrow=c(1,2));style()
for(g in c(0,1)){
 v<-z[z$gpus==g,]
 plot(range(v$cpus),range(v$wall_seconds_min,v$wall_seconds_max),type="n",log="xy",xaxt="n",
      xlab="Allocated physical CPU cores",ylab="Completion time (s)",main=if(g==0)"CPU only"else"One A100 available + CPUs")
 axis(1,at=sort(unique(v$cpus)),labels=sort(unique(v$cpus)),cex.axis=.75)
 for(runtime in c("rcompss","parsec")){
  w<-v[v$runtime==runtime,];w<-w[order(w$cpus),]
  lines(w$cpus,w$wall_seconds,type="b",col=colors[runtime],pch=if(runtime=="rcompss")16 else 17)
  arrows(w$cpus,w$wall_seconds_min,w$cpus,w$wall_seconds_max,code=3,angle=90,length=.025,col=colors[runtime])
  under<-w[w$active_gpus_min<w$gpus,]
  if(nrow(under))text(under$cpus,under$wall_seconds,labels=paste0(under$active_gpus_min,"/",under$gpus),pos=3,cex=.6)
 }
 legend("topright",c("RCOMPSs","PaRSEC"),col=colors,pch=c(16,17),bty="n",cex=.75)
}
dev.off()
z<-d[d$study=="size",]
pdf(file.path(out,"ibex_gemm_memory.pdf"),width=7.1,height=3.2);par(mfrow=c(1,2));style()
for(metric in c("host_peak_pss_bytes","gpu_peak_total_bytes")){
 plot(range(z$n),range(0,z[[paste0(metric,"_max")]]/1024^3),type="n",
      xlab="Matrix dimension N",ylab="Peak memory (GiB)",
      main=if(metric=="host_peak_pss_bytes")"Host: summed process PSS"else"Device: simultaneous sum across GPUs")
 series(z,"n",metric,1024^3,TRUE)
 if(metric=="host_peak_pss_bytes")legend("topleft",legend=labels,col=rep(colors,3),
   pch=as.vector(rbind(shapes,shapes-15)),lty=rep(line,each=2),cex=.6,bty="n",ncol=2)
}
dev.off()
writeLines("Measured medians; whiskers show minimum/maximum of3 runs. Host PSS sampled every0.5s; GPU memory targets50ms through NVML (plus query overhead). Host PSS sums case-tagged master/workers, avoiding RSS shared-page double counting. GPU peak is simultaneous per-case summed process GPU memory; no arithmetic sum of separate device peaks. Fresh-process timing includes runtime startup, generation, complete output and shutdown. PaRSEC and RCOMPSs use different layouts and input generators. See campaign methodology for validation and task partitioning.",file.path(out,"CAPTIONS.txt"))
