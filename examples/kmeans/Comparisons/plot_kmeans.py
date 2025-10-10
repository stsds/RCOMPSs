import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.lines as mlines

# Read CSV file
df = pd.read_csv("comp_kmeans.csv", header=None)
df = df.iloc[:, [0, 2, 15]]

df.columns = ["package", "size", "time"]

df = df.groupby(["package", "size"], as_index=False)["time"].mean()

group_name_map = {
    "KMEANS_PARALLEL": "parallel",
    "KMEANS_FURRR": "furrr",
    "KMEANS_FUTURE": "future",
    "KMEANS_RCOMPSs": "RCOMPSs",
    "KMEANS_Sequential": "R base sequential"
}

# First subplot
import itertools

# Assign colors to algorithm groups (not package)
algorithm_color_map = {
    "parallel": "tab:green",
    "furrr": "tab:orange",
    "future": "tab:purple",
    "RCOMPSs": "tab:red",
    "R base sequential": "black"
}


# Track which algorithm groups have been added to the legend
algorithm_handles = {}
for group, data in df.groupby("package"):
    label = group_name_map.get(group, group)
    algo_group = label
    color = algorithm_color_map.get(algo_group, None)
    if group == "R_sequential":
        color = "black"
    # Convert to numpy arrays to avoid pandas multi-dimensional indexing errors
    x = data["size"].to_numpy()
    y = data["time"].to_numpy()
    plt.scatter(x, y, label=label, color=color)
    plt.plot(x, y, linewidth=2, color=color)
    # Only add one handle per algorithm group
    if algo_group not in algorithm_handles:
        algorithm_handles[algo_group] = mlines.Line2D([], [], color=color, label=algo_group)


with PdfPages("kmeans_comparison.pdf") as pdf:
    # Create a fresh figure for the plot
    plt.figure()
    algorithm_handles = {}
    for group, data in df.groupby("package"):
        label = group_name_map.get(group, group)
        algo_group = label
        color = algorithm_color_map.get(algo_group, None)
        if group == "R_sequential":
            color = "black"
        x = data["size"].to_numpy()
        y = data["time"].to_numpy()
        plt.scatter(x, y, label=label, color=color)
        plt.plot(x, y, linewidth=2, color=color)
        if algo_group not in algorithm_handles:
            algorithm_handles[algo_group] = mlines.Line2D([], [], color=color, label=algo_group)
    first_legend = plt.legend(handles=list(algorithm_handles.values()), title="Algorithm group", loc="upper left")
    plt.gca().add_artist(first_legend)
    # Add second legend only if bigmemory_handles is defined
    if 'bigmemory_handles' in globals():
        try:
            plt.legend(handles=bigmemory_handles, title="Bigmemory usage", loc="upper right")
        except Exception:
            # if it's not the right type, ignore
            pass
    plt.xlabel("Number of points")
    plt.ylabel("Execution time (seconds)")
    plt.title("Kmeans Execution Time Comparison (Average of 10 runs)")
    pdf.savefig()
    plt.close()
