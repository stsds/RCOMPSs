import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Read CSV file
df_parallel = pd.read_csv("parallel.csv", header = None)
df = pd.read_csv("res.csv", header = None)
df_futurebigmemory = pd.read_csv("futurebigmemory.csv", header = None)
df_mirai = pd.read_csv("mirai.csv", header = None)

df_parallel = df_parallel.iloc[:, [0, 2, 13, 14]]
df = df.iloc[:, [0, 2, 14, 15]]
df_futurebigmemory = df_futurebigmemory.iloc[:, [0, 2, 14, 15]]
df_mirai = df_mirai.iloc[:, [0, 2, 14, 15]]

res = np.vstack([df_parallel.values, df.values, df_futurebigmemory.values, df_mirai.values])
res = pd.DataFrame(res)
res.columns = ["package", "size", "time", "repetition"]

# Update package names in res before creating res1 and res2
#res.loc[(res["package"] == "KMEANS_RESULTS") & (res["repetition"] == 1), "package"] = "RCOMPSs1"
#res.loc[(res["package"] == "KMEANS_RESULTS") & (res["repetition"] != 1), "package"] = "RCOMPSs2"

res = res.groupby(["package", "size"], as_index=False)["time"].mean()

group_name_map = {
    "KMEANS_PARALLEL": "parallel",
    "KMEANS_FUTUREAPPLY": "future.apply",
    "KMEANS_FURRR": "furrr",
    "KMEANS_FUTUREBIGMEMORY": "future",
    "KMEANS_RESULTS": "RCOMPSs",
    "KMEANS_MIRAI": "mirai",
    "R_sequential": "R base sequential"
}

# First subplot
for group, data in res.groupby("package"):
    label = group_name_map.get(group, group)
    if group == "R_sequential":
        linestyle = '--'
        color = "black"
    else:
        linestyle = '-'
        color = None
    plt.scatter(data["size"], data["time"], label=label, color=color)
    plt.plot(data["size"], data["time"], linewidth=2, linestyle=linestyle, color=color)  # Apply linestyle and color

plt.xlabel("Number of points")
plt.ylabel("Execution time (seconds)")
plt.ylim(0, 85)
plt.legend(title="Packages")
plt.title("K-means Execution Time Comparison (Average of 6 runs)")
#plt.suptitle("RCOMPSs1: Execution time of the first repetition\nRCOMPSs2: Average execution time of the next 5 repetitions",
#             fontsize=8, y=0.93)
plt.savefig("kmeans_execution_time_comparison.pdf", bbox_inches="tight")
plt.show()
