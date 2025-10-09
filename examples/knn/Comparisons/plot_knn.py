import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.lines as mlines

# Read CSV file
df = pd.read_csv("comp_knn.csv", header=None)
df = df.iloc[:, [0, 3, 15]]
df.columns = ["package", "size", "time"]

# Aggregate by package and size (mean time)
df = df.groupby(["package", "size"], as_index=False)["time"].mean()

# Map package ids to friendly labels
group_name_map = {
    "KNN_RES_PARALLEL": "parallel",
    "KNN_RES_FURRR": "furrr",
    "KNN_RES_FUTURE": "future",
    "KNN_RES_RCOMPSs": "RCOMPSs",
    "KNN_RES_Sequential": "R base sequential"
}

# Colors for each algorithm group
algorithm_color_map = {
    "parallel": "tab:green",
    "furrr": "tab:orange",
    "future": "tab:purple",
    "RCOMPSs": "tab:red",
    "R base sequential": "black"
}


with PdfPages("KNN_comparison.pdf") as pdf:
    fig, ax = plt.subplots(figsize=(8, 5))

    algorithm_handles = {}

    # Plot each package as scatter + line (sorted by size)
    for group, data in df.groupby("package"):
        label = group_name_map.get(group, group)
        color = algorithm_color_map.get(label, None)
        x = data["size"].to_numpy(dtype=float)
        y = data["time"].to_numpy(dtype=float)
        # sort by x so lines connect in order
        order = np.argsort(x)
        x = x[order]
        y = y[order]
        # mask finite values
        mask = np.isfinite(x) & np.isfinite(y)
        if not np.any(mask):
            continue
        xm, ym = x[mask], y[mask]
        ax.scatter(xm, ym, label=label, color=color)
        ax.plot(xm, ym, linewidth=1.5, color=color)
        # add legend handle
        if label not in algorithm_handles:
            algorithm_handles[label] = mlines.Line2D([], [], color=color, label=label)

    # add legend
    if algorithm_handles:
        first_legend = ax.legend(handles=list(algorithm_handles.values()), title="Algorithm group", loc="upper left")
        ax.add_artist(first_legend)

    ax.set_xlabel("Number of points")
    ax.set_ylabel("Execution time (seconds)")
    ax.set_title("KNN Execution Time Comparison (Average of runs)")

    pdf.savefig(fig)
    plt.close(fig)
