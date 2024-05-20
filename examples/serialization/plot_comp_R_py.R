library(ggplot2)

per_R <- read.csv("time_R.csv")
per_py <- read.csv("time_python.csv")

time <- rbind(per_R, per_py)

pdf("time.pdf")

ggplot(data = time, mapping = aes(x = block_size, y = ser_time + unser_time, color = method)) +
  geom_point() +
  geom_line() +
  labs(title = "Serialization time", x = "Matrix dimension", y = "Time(s)") +
  ggtitle("[Serialization + I/O] time comparison") +
  theme_minimal()

ggplot(data = time, mapping = aes(x = block_size, y = log10(ser_time + unser_time), color = method)) +
  geom_point() +
  geom_line() +
  labs(title = "Serialization time", x = "Matrix dimension", y = "log10(Time(s))") +
  ggtitle("[Serialization + I/O] time comparison (log10 scale)") +
  theme_minimal()

dev.off()
