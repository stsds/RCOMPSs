import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Read CSV file
df = pd.read_csv("/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/examples/kmeans/Comparisons/plot/iter=20/res3.csv", header = None)
df = df.iloc[:, [0, 2, 15]]
df.columns = ["package", "size", "time"]

df = df.groupby(["package", "size"], as_index=False)["time"].mean()

group_name_map = {
    "KMEANS_PARALLEL": "parallel",
    "KMEANS_PARALLELBIGMEMORY": "parallel & bigmemory",
    "KMEANS_FUTUREAPPLY": "future.apply",
    "KMEANS_FUTUREAPPLY_BIGMEMORY": "future.apply & bigmemory",
    "KMEANS_FURRR": "furrr",
    "KMEANS_FUTURE": "future",
    "KMEANS_FUTUREBIGMEMORY": "future & bigmemory",
    "KMEANS_RCOMPSs": "RCOMPSs",
    "KMEANS_MIRAI": "mirai",
    "KMEANS_R_sequential": "R base sequential"
}

# First subplot
for group, data in df.groupby("package"):
    label = group_name_map.get(group, group)
    if group == "KMEANS_R_sequential":
        linestyle = '--'
        color = "black"
    else:
        linestyle = '-'
        color = None
    plt.scatter(data["size"], data["time"], label=label, color=color)
    plt.plot(data["size"], data["time"], linewidth=2, linestyle=linestyle, color=color)  # Apply linestyle and color

plt.xlabel("Number of points")
plt.ylabel("Execution time (seconds)")
#plt.ylim(0, 500)
plt.legend(title="Packages")
plt.title("K-means Execution Time Comparison (Average of 6 runs)")
#plt.suptitle("RCOMPSs1: Execution time of the first repetition\nRCOMPSs2: Average execution time of the next 5 repetitions",
#             fontsize=8, y=0.93)
plt.savefig("/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/examples/kmeans/Comparisons/plot/iter=20/kmeans_execution_time_comparison.pdf", bbox_inches="tight")
#plt.show()
