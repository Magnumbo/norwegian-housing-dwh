"""Plot the dwelling stock in the Ålesund area across the 2020 merger and 2024 split."""

import os

import matplotlib.pyplot as plt
import pandas as pd
from databricks import sql
from dotenv import load_dotenv
from matplotlib.ticker import StrMethodFormatter

load_dotenv()  # reads .env into os.environ

with sql.connect(
    server_hostname=os.environ["DATABRICKS_HOST"],
    http_path=os.environ["DATABRICKS_HTTP_PATH"],
    access_token=os.environ["DATABRICKS_TOKEN"],
) as conn:
    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT code, year, g.name, SUM(dwellings) AS dwellings
            FROM nor_housing.gold.dim_geography AS g
            INNER JOIN nor_housing.gold.fct_dwellings AS d
                ON g.geography_key = d.geography_key
            WHERE area_code = '1508'
            GROUP BY code, year, g.name
            ORDER BY code, year
        """)
        df = cursor.fetchall_arrow().to_pandas()

code_to_layer = {
    "1504": "Ålesund",
    "1508": "Ålesund",
    "1534": "Haram",
    "1580": "Haram",
    "1523": "Skodje, Ørskog, Sandøy",
    "1529": "Skodje, Ørskog, Sandøy",
    "1546": "Skodje, Ørskog, Sandøy",
    "1507": "Merged (2020–2023)",
}

df["layer"] = df["code"].map(code_to_layer)

wide = df.pivot_table(
    index="year",
    columns="layer",
    values="dwellings",
    aggfunc="sum",
    fill_value=0,
)


# Bottom to top: the largest, most stable layer first
layer_order = ["Ålesund", "Skodje, Ørskog, Sandøy", "Haram", "Merged (2020–2023)"]
layer_colors = ["#2a78d6", "#1baf7a", "#eb6834", "#b5b5b5"]
wide = wide[layer_order]

# What a naive query on the name "Ålesund" returns: 1504, then 1507, then 1508
naive_by_name = df[df["name"] == "Ålesund"].groupby("year")["dwellings"].sum()
naive_label = 'Naive: a query on the name "Ålesund"'

# What a query on the stable area returns: the sum of every layer, every year
harmonised = wide.sum(axis=1)
harmonised_label = 'Harmonised: a query on the area "Haram + Ålesund"'

fig, ax = plt.subplots(figsize=(10, 5.5), layout="constrained")

bottom = pd.Series(0, index=wide.index)
for layer, color in zip(layer_order, layer_colors, strict=True):
    ax.bar(
        wide.index,
        wide[layer],
        bottom=bottom,
        color=color,
        edgecolor="white",
        linewidth=0.8,
        hatch="///" if layer.startswith("Merged") else None,
        label=layer,
    )
    bottom += wide[layer]

ax.plot(
    harmonised.index,
    harmonised.values,
    color="#1a1a19",
    linewidth=2.5,
    marker="o",
    markersize=4,
    label=harmonised_label,
)
ax.plot(
    naive_by_name.index,
    naive_by_name.values,
    color="#1a1a19",
    linewidth=2,
    linestyle="--",
    marker="o",
    markersize=4,
    label=naive_label,
)

# Label each boundary change on the outer side of its line
for year, text, side in [
    (2019.5, "2020: five municipalities merge", "right"),
    (2023.5, "2024: Haram split out", "left"),
]:
    ax.axvline(year, color="#52514e", linewidth=1, linestyle=":")
    ax.annotate(
        text,
        xy=(year, 37500),
        xytext=(-4 if side == "right" else 4, 0),
        textcoords="offset points",
        ha=side,
        fontsize=9,
        color="#52514e",
    )

ax.set_title(
    "Two queries for the same place: dwellings in the Ålesund area, 2006–2026\n"
    "The bars show the municipalities SSB reported each year",
    fontsize=12,
    loc="left",
)
ax.set_ylim(0, 39000)
ax.yaxis.set_major_formatter(StrMethodFormatter("{x:,.0f}"))  # 34084 -> 34,084
ax.grid(axis="y", color="#e5e5e5", linewidth=0.8)
ax.set_axisbelow(True)
ax.spines[["top", "right"]].set_visible(False)
ax.tick_params(colors="#52514e", labelsize=9)

# Legend in reading order: the layers bottom to top, then the naive line
handles, labels = ax.get_legend_handles_labels()
order = [labels.index(label) for label in [*layer_order, harmonised_label, naive_label]]
fig.legend(
    [handles[i] for i in order],
    [labels[i] for i in order],
    loc="outside lower center",
    ncols=3,
    frameon=False,
    fontsize=9,
)

fig.savefig("docs/img/alesund_area.png", dpi=150, facecolor="white")
