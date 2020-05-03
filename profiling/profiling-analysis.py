##
import pandas as pd
import altair as alt

##
rawdf = pd.read_json("../profiling-result-unfair.json", lines=True, orient="records")

##
rawdf["ElapsedPlot"] = rawdf.Elapsed.apply(
    lambda d: d["plot"] if isinstance(d, dict) else 0
)
rawdf["ElapsedPlotCorrelation"] = rawdf.Elapsed.apply(
    lambda d: d["plot"] if isinstance(d, dict) else 0
)
rawdf["ElapsedPlotMissing"] = rawdf.Elapsed.apply(
    lambda d: d["plot"] if isinstance(d, dict) else 0
)
rawdf["ElapsedTot"] = rawdf["Elapsed"]
rawdf["ElapsedTot"] = rawdf.Elapsed.apply(
    lambda d: sum(d.values()) if isinstance(d, dict) else d
)
pdf = rawdf.pivot_table(
    index=["Mem", "CPU", "Dataset", "Row", "Col"],
    columns="Library",
    values="ElapsedTot",
).reset_index()
pdf["Ratio"] = pdf["pandas-profiling"] / pdf["dataprep"]

##
alt.Chart(pdf).mark_bar().encode(
    x="CPU:N",
    y="Mem:O",
    color="Ratio:Q",
    tooltip="Ratio:Q",
    column="Col:O",
    row="Row:O",
).resolve_axis("independent")

##
alt.Chart(
    rawdf[(rawdf.CPU == 1) & rawdf.Mem.isin(["2G"]) & (rawdf.Col == 52)]
).mark_bar().encode(
    y="Library:N", x="ElapsedTot", color="Library", tooltip="ElapsedTot", row="Row:Q",
)

##

##


##
d = [
    {"Pallavi": 3, "Madana": 3, "Kenneth": 2, "Sanjana": 2},
    {"Kenneth": 3, "Sanjana": 3, "Pallavi": 3, "Suraj": 2},
    {"Madana": 3, "Suraj": 2, "Pallavi": 1},
    {"Pallavi": 3, "Suraj": 2, "Madana": 1},
    {"Sanjana": 3, "Kenneth": 2, "Zhixuan": 1},
    {"Suraj": 3, "Linghao": 3, "Zhixuan": 3, "Kenneth": 2, "Sanjana": 2, "Pallavi": 2},
]

from collections import defaultdict
from operator import itemgetter

rank = defaultdict(int)
for dic in d:
    for name, weight in dic.items():
        rank[name] += weight

rank = sorted(rank.items(), key=itemgetter(1), reverse=True)
