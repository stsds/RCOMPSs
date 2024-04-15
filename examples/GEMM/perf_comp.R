library(ggplot2)

t <- read.table("time.csv", sep = ",", header = FALSE)
colnames(t) <- c("time", "method", "dimension", "tilesize")
for(j in c(1,3,4)){
  t[,j] <- as.numeric(t[,j])
}
t$method <- as.factor(t$method)
#print(t)

pdf("perf_comp.pdf")
ggplot(t, aes(x = tilesize, y = time)) +
  geom_point(aes(colour = method))
dev.off()
