#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library(ggplot2)

t <- read.table(args[1], sep = ",", header = FALSE)
colnames(t) <- c("time", "method", "dimension", "tilesize")
for(j in c(1,3,4)){
  t[,j] <- as.numeric(t[,j])
}
t$method <- as.factor(t$method)
#print(t)

pdf(arg[2])
ggplot(t, aes(x = tilesize, y = time)) +
  geom_point(aes(colour = method))
dev.off()
