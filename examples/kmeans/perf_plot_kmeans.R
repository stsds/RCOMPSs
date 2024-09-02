perf <- read.table("perf_kmeans.csv", header = FALSE, sep = ",")
perf <- unique(perf)
colnames(perf) <- c("KMEANS_RESULTS",
      "seed",
      "numpoints",
      "dimensions",
      "num_centres",
      "num_fragments",
      "mode",
      "iterations",
      "epsilon",
      "arity",
      "type",
      "R_version",
      "Initialization_time",
      "Kmeans_time",
      "Total_time"
)

library(ggplot2)

pdf("perf_kmeans.pdf")
# Plot1: Total kmeans time with all the data
ggplot(perf, aes(numpoints, Kmeans_time, colour = type)) + 
  geom_point() +
  xlab("Number of points") + ylab("K-means time (seconds)") + ggtitle("K-means time")

# Plot2: Initialization time
ggplot(perf, aes(numpoints, Initialization_time, colour = type)) +
  geom_point() +
  xlab("Number of points") + ylab("Initialization time (seconds)") + ggtitle("Initialization time")

# Plot3: Comparision between RCOMPSs and R_sequential
dat3 <- perf[which(perf$type %in% c("RCOMPSs", "R_sequential")),]
dat3 <- dat3[which(dat3$numpoints >= 1e8),]
dat3_plot <- as.data.frame(matrix(nrow = 0, ncol = ncol(dat3)))
colnames(dat3_plot) <- colnames(perf)
for(n in unique(dat3$numpoints)){
  tmp <- dat3[which(dat3$numpoints == n),]
  tmp_RCOMPSs <- tmp[which(tmp$type == "RCOMPSs"),]
  tmp_R_sequential <- tmp[which(tmp$type == "R_sequential"),]
  dat3_plot <- rbind(dat3_plot, 
                     tmp_RCOMPSs[which.min(tmp_RCOMPSs$Kmeans_time),],
                     tmp_R_sequential[which.min(tmp_R_sequential$Kmeans_time),]
                     )
  cat("numpoints = ", n, "; speedup: ", tmp_R_sequential[which.min(tmp_R_sequential$Kmeans_time),14] / tmp_RCOMPSs[which.min(tmp_RCOMPSs$Kmeans_time),14], "\n", sep = "")
}
ggplot(dat3_plot, aes(numpoints, Kmeans_time, colour = type)) +
  geom_point() + geom_line() +
  xlab("Number of points") + ylab("K-means time (seconds)") + ggtitle("K-means time") +
  scale_color_manual(name = "Execution type", labels = c("R sequential", "RCOMPSs"), values = c("darkblue", "red"))
dev.off()
