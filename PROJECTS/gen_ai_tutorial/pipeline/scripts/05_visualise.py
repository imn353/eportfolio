"""05_visualise.py - Stage 5 of the pipeline.

Reads from the SQLite warehouse (pipeline.db / gold_air_quality) and
writes three PNG charts to output/charts/.

Adaptations to the NYC dataset (carried forward from Stages 3 and 4):
    spec: 'country'   -> geo_type_name (no country in NYC-only data)
    spec: 'city'      -> geo_place_name
    spec: 'AQI'       -> data_value (PM2.5 in mcg/m3)
"""

import sqlite3
from pathlib import Path

# Use the non-interactive Agg backend BEFORE importing pyplot so the
# script runs headless (no window pops up, works fine on a server / CI).
import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt  # noqa: E402
import pandas as pd  # noqa: E402
import seaborn as sns  # noqa: E402

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "pipeline.db"
CHARTS_DIR = PROJECT_ROOT / "output" / "charts"

TABLE_NAME = "gold_air_quality"
SUBTITLE = "Source: pipeline.db — gold_air_quality"

# Consistent visual style across all three charts.
sns.set_theme(style="whitegrid", context="talk")


def _save(fig: plt.Figure, path: Path) -> None:
    # tight_layout + a top margin so the figure-level suptitle doesn't
    # collide with the axes-level subtitle.
    fig.tight_layout(rect=(0, 0, 1, 0.94))
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def chart_top15_cities(df: pd.DataFrame, out_path: Path) -> None:
    # Top-15 by mean PM2.5. Descending order so the most-polluted bar
    # sits at the top of the horizontal chart (seaborn places the first
    # label at the top of the y-axis).
    top15 = (
        df.groupby("geo_place_name")["data_value"]
        .mean()
        .sort_values(ascending=False)
        .head(15)
    )

    fig, ax = plt.subplots(figsize=(11, 7))
    sns.barplot(x=top15.values, y=top15.index, ax=ax, palette="Reds_r", hue=top15.index, legend=False)
    ax.set_xlabel("Average PM2.5 (mcg/m3)")
    ax.set_ylabel("Neighborhood (geo_place_name)")
    fig.suptitle("Top 15 Most Polluted NYC Neighborhoods", fontsize=15, fontweight="bold")
    ax.set_title(SUBTITLE, fontsize=10, style="italic", loc="left")
    _save(fig, out_path)


def chart_aqi_category_distribution(df: pd.DataFrame, out_path: Path) -> None:
    # Row count per aqi_category. Only categories actually present are plotted
    # (Good and Moderate on this dataset); empty buckets would distort the pie.
    counts = df["aqi_category"].value_counts()

    fig, ax = plt.subplots(figsize=(8, 8))
    colors = sns.color_palette("YlOrRd", n_colors=len(counts))
    ax.pie(
        counts.values,
        labels=counts.index,
        autopct=lambda p: f"{p:.1f}%\n(n={int(round(p * counts.sum() / 100)):,})",
        startangle=90,
        colors=colors,
        wedgeprops={"edgecolor": "white", "linewidth": 2},
    )
    ax.set_ylabel("")  # pie charts: kill the default y-label
    fig.suptitle("Distribution of Rows by AQI Category", fontsize=15, fontweight="bold")
    ax.set_title(SUBTITLE, fontsize=10, style="italic", loc="center")
    _save(fig, out_path)


def chart_avg_aqi_by_country(df: pd.DataFrame, out_path: Path) -> None:
    # "Country" -> geo_type_name. The NYC dataset has only 5 distinct
    # values so the "top 15" cap is a no-op here, but the head(15) keeps
    # the logic correct if the data ever changes.
    by_country = (
        df.groupby("geo_type_name")["data_value"]
        .mean()
        .sort_values(ascending=False)
        .head(15)
    )

    fig, ax = plt.subplots(figsize=(11, 6.5))
    sns.barplot(x=by_country.index, y=by_country.values, ax=ax, palette="Blues_r", hue=by_country.index, legend=False)
    ax.set_xlabel("Region (geo_type_name) - country N/A for NYC-only data")
    ax.set_ylabel("Average PM2.5 (mcg/m3)")
    fig.suptitle("Average AQI by Country (Top 15)", fontsize=15, fontweight="bold")
    ax.set_title(SUBTITLE, fontsize=10, style="italic", loc="left")
    _save(fig, out_path)


def main() -> None:
    # 1. Pull the gold table out of SQLite. The `with` block closes the
    #    connection automatically once we leave it.
    print(f"Connecting to {DB_PATH} ...")
    with sqlite3.connect(DB_PATH) as conn:
        df = pd.read_sql_query(f"SELECT * FROM {TABLE_NAME}", conn)
    print(f"Loaded {len(df)} rows from '{TABLE_NAME}'.")

    # 2. Make sure the output dir exists.
    CHARTS_DIR.mkdir(parents=True, exist_ok=True)

    # 3. Generate the three charts.
    paths = {
        "top15_cities": CHARTS_DIR / "top15_cities.png",
        "aqi_category_distribution": CHARTS_DIR / "aqi_category_distribution.png",
        "avg_aqi_by_country": CHARTS_DIR / "avg_aqi_by_country.png",
    }
    chart_top15_cities(df, paths["top15_cities"])
    chart_aqi_category_distribution(df, paths["aqi_category_distribution"])
    chart_avg_aqi_by_country(df, paths["avg_aqi_by_country"])

    # 4. Report what we wrote.
    print("\nSaved charts:")
    for key, p in paths.items():
        print(f"  {key}: {p}")


if __name__ == "__main__":
    main()
