import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.lines as mlines

# Read CSV file
df = pd.read_csv("/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/examples/kmeans/Comparisons/plot/iter=30/res1.csv", header = None)
df = df.iloc[:, [0, 2, 15]]

df.columns = ["package", "size", "time"]

# Add a column indicating whether bigmemory is used
def uses_bigmemory(pkg):
    return int("BIGMEMORY" in pkg.upper())
df["bigmemory"] = df["package"].apply(uses_bigmemory)

# Update package names in res before creating res1 and res2
#res.loc[(res["package"] == "KMEANS_RESULTS") & (res["repetition"] == 1), "package"] = "RCOMPSs1"
#res.loc[(res["package"] == "KMEANS_RESULTS") & (res["repetition"] != 1), "package"] = "RCOMPSs2"


# Exclude the largest time for KMEANS_RCOMPSs and KMEANS_RCOMPSs_BIGMEMORY
def exclude_max_time(df, package_name):
    mask = df["package"] == package_name
    subdf = df[mask]
    if not subdf.empty:
        max_idx = subdf["time"].idxmax()
        df = df.drop(max_idx)
    return df

df = exclude_max_time(df, "KMEANS_RCOMPSs")
df = exclude_max_time(df, "KMEANS_RCOMPSs_BIGMEMORY")

df = df.groupby(["package", "size"], as_index=False)["time"].mean()

group_name_map = {
    "KMEANS_PARALLEL": "parallel",
    "KMEANS_PARALLELBIGMEMORY": "parallel",
    "KMEANS_FUTUREAPPLY": "future.apply",
    "KMEANS_FUTUREAPPLY_BIGMEMORY": "future.apply",
    "KMEANS_FURRR": "furrr",
    "KMEANS_FUTURE": "future",
    "KMEANS_FUTUREBIGMEMORY": "future",
    "KMEANS_RCOMPSs": "RCOMPSs",
    "KMEANS_RCOMPSs_BIGMEMORY": "RCOMPSs",
    "KMEANS_MIRAI": "mirai",
    "R_sequential": "R base sequential"
}

# First subplot
import itertools

# Assign colors to algorithm groups (not package)
algorithm_color_map = {
    "parallel": "tab:green",
    "future.apply": "tab:orange",
    #"furrr": "tab:green",
    "future": "tab:purple",
    "RCOMPSs": "tab:red",
    #"mirai": "tab:brown",
    "R base sequential": "black"
}

# Marker and line style for bigmemory
marker_map = {0: "o", 1: "s"}  # circle for normal, square for bigmemory
linestyle_map = {0: "-", 1: "--"}  # solid for normal, dotted for bigmemory


# Track which algorithm groups have been added to the legend
algorithm_handles = {}
for group, data in df.groupby("package"):
    label = group_name_map.get(group, group)
    algo_group = label
    color = algorithm_color_map.get(algo_group, None)
    bigmemory_used = int("BIGMEMORY" in group.upper())
    marker = marker_map[bigmemory_used]
    linestyle = linestyle_map[bigmemory_used]
    if group == "R_sequential":
        linestyle = ':'
        color = "black"
        marker = "x"
    plt.scatter(data["size"], data["time"], label=label, color=color, marker=marker)
    plt.plot(data["size"], data["time"], linewidth=2, linestyle=linestyle, color=color)
    # Only add one handle per algorithm group
    if algo_group not in algorithm_handles:
        algorithm_handles[algo_group] = mlines.Line2D([], [], color=color, marker=marker_map[0], linestyle='None', label=algo_group)

# Legend for bigmemory usage
bigmemory_handles = [
    mlines.Line2D([], [], color='gray', marker='o', linestyle='None', label='No bigmemory'),
    mlines.Line2D([], [], color='gray', marker='s', linestyle='None', label='Use bigmemory')
]

with PdfPages("/home/zhanx0q/1Projects/2023-2Summer/RCOMPSs/2025/COMPSs/Bindings/RCOMPSs/examples/kmeans/Comparisons/plot/iter=30/kmeans_execution_time_comparison.pdf") as pdf:
    # First plot
    algorithm_handles = {}
    for group, data in df.groupby("package"):
        label = group_name_map.get(group, group)
        algo_group = label
        color = algorithm_color_map.get(algo_group, None)
        bigmemory_used = int("BIGMEMORY" in group.upper())
        marker = marker_map[bigmemory_used]
        linestyle = linestyle_map[bigmemory_used]
        if group == "R_sequential":
            linestyle = ':'
            color = "black"
            marker = "x"
        plt.scatter(data["size"], data["time"], label=label, color=color, marker=marker)
        plt.plot(data["size"], data["time"], linewidth=2, linestyle=linestyle, color=color)
        if algo_group not in algorithm_handles:
            algorithm_handles[algo_group] = mlines.Line2D([], [], color=color, marker=marker_map[0], linestyle='None', label=algo_group)
    first_legend = plt.legend(handles=list(algorithm_handles.values()), title="Algorithm group", loc="upper left")
    plt.gca().add_artist(first_legend)
    plt.legend(handles=bigmemory_handles, title="Bigmemory usage", loc="upper right")
    plt.xlabel("Number of points")
    plt.ylabel("Execution time (seconds)")
    plt.title("K-means Execution Time Comparison (Average of 5 runs)")
    pdf.savefig()
    plt.close()

    # Second plot: average time difference to RCOMPSs
    plt.figure()
    sizes = sorted(df["size"].unique())

    # Use only KMEANS_RCOMPSs as the base for comparison
    rcompss_base_df = df[df["package"] == "KMEANS_RCOMPSs"].groupby("size")["time"].mean()

    algorithm_handles2 = {}
    for group, data in df.groupby("package"):
        if group == "KMEANS_RCOMPSs":
            continue
        label = group_name_map.get(group, group)
        color = algorithm_color_map.get(label, None)
        bigmemory_used = int("BIGMEMORY" in group.upper())
        marker = marker_map[bigmemory_used]
        merged = pd.merge(data, rcompss_base_df, left_on="size", right_index=True, suffixes=("", "_rc"))
        merged["diff"] = merged["time"] - merged["time_rc"]
        plt.plot(merged["size"], merged["diff"], color=color)
        plt.scatter(merged["size"], merged["diff"], color=color, marker=marker, label=label)
        if label not in algorithm_handles2:
            algorithm_handles2[label] = mlines.Line2D([], [], color=color, marker=marker_map[0], linestyle='None', label=label)
    plt.axhline(y=0, color='gray', linestyle='--', linewidth=1)  # horizontal baseline
    plt.yscale('symlog', linthresh=1)  # linear for y<=0, log for y>0
    first_legend2 = plt.legend(handles=list(algorithm_handles2.values()), title="Algorithm group", loc="lower left")
    plt.gca().add_artist(first_legend2)
    plt.legend(handles=bigmemory_handles, title="Bigmemory usage", loc="lower right")
    plt.xlabel("Number of points")
    plt.ylabel("Average time difference to RCOMPSs (seconds)")
    plt.title("Average Time Difference to RCOMPSs by Package")
    pdf.savefig()
    plt.close()
