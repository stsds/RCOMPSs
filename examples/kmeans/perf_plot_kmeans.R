perf <- read.table("perf_kmeans.csv", header = FALSE, sep = ",")
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
ggplot(perf, aes(numpoints, Kmeans_time, colour = type)) + 
  geom_point() +
  xlab("Number of points") + ylab("K-means time (second)") + ggtitle("K-means time")
ggplot(perf, aes(numpoints, Initialization_time, colour = type)) +
  geom_point() +
  xlab("Number of points") + ylab("Initialization time (second)") + ggtitle("Initialization time")
dev.off()
