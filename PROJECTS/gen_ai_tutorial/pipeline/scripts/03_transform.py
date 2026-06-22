"""03_transform.py — Stage 3 of the pipeline (Gold layer).

============================================================================
 Gold layer in the Medallion architecture
============================================================================
 The Gold layer is the business-level tier: it takes the trustworthy
 Silver data and enriches it with the concepts an analyst actually wants
 to query — categories, time buckets, derived metrics, aggregations.

 Gold is the layer that downstream consumers (dashboards, the SQLite
 warehouse in Stage 4, the charts in Stage 5) read from. It is the
 "answer-shaped" version of the data: row-level data plus the analytic
 columns needed to slice it.

 Concretely, this script:
   * Filters Silver to a single comparable pollution metric.
   * Adds an aqi_category column derived from EPA-style thresholds.
   * Extracts year and month from the date column.
   * Prints aggregations (by region, by city, monthly trend, top/bottom 10).
   * Writes the enriched row-level DataFrame to data/gold/gold_data.csv.

============================================================================
 Adaptations to this dataset (NYC Air Quality Surveillance)
============================================================================
 The original spec assumed a multi-country AQI dataset. The dataset we
 actually have is NYC-only, with no country column, no real "city"
 column, and 18 different pollution indicators in incompatible units.
 To honour the spirit of the spec we substitute:

   * "country"  -> geo_type_name (Borough / UHF42 / CD / UHF34 / Citywide)
                    labelled "region" in output, because country is N/A.
   * "city"     -> geo_place_name (NYC neighbourhoods, 114 unique values).
   * "AQI"      -> Fine particles (PM 2.5), data_value in mcg/m3.
                    Filtering to one indicator makes averages meaningful;
                    averaging across PM2.5/NO2/Ozone/mortality rates does
                    not.

 The 4-bucket aqi_category thresholds are calibrated to PM2.5 mcg/m3
 (derived from US EPA 24-hour AQI breakpoints):
    Good       < 12
    Moderate   12 to < 35
    Unhealthy  35 to < 55
    Hazardous  >= 55
============================================================================
"""

from pathlib import Path

import numpy as np
import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SILVER_INPUT_PATH = PROJECT_ROOT / "data" / "silver" / "silver_data.csv"
GOLD_OUTPUT_PATH = PROJECT_ROOT / "data" / "gold" / "gold_data.csv"

# Single comparable indicator. Filtering to one indicator keeps averages
# meaningful — the silver data mixes units (mcg/m3, ppb, per-100k, etc).
AQI_INDICATOR = "Fine particles (PM 2.5)"

# PM2.5 (mcg/m3) thresholds, collapsed into 4 buckets from the EPA 24-hour
# AQI breakpoints. Tweaking these is a one-line change.
AQI_BINS = [-np.inf, 12, 35, 55, np.inf]
AQI_LABELS = ["Good", "Moderate", "Unhealthy", "Hazardous"]


def main() -> None:
    # 1. Load Silver. parse_dates restores the datetime dtype lost on CSV round-trip.
    print(f"Loading {SILVER_INPUT_PATH} ...")
    df = pd.read_csv(SILVER_INPUT_PATH, parse_dates=["start_date"])

    # 2. Filter to the AQI proxy. Bail loudly if it's missing — protects
    #    against future data drift where the indicator name might change.
    if AQI_INDICATOR not in df["name"].unique():
        raise ValueError(
            f"Expected indicator '{AQI_INDICATOR}' not found in silver data. "
            f"Available indicators: {sorted(df['name'].unique())}"
        )
    df = df[df["name"] == AQI_INDICATOR].copy()
    print(f"\nFiltered to indicator: '{AQI_INDICATOR}' ({len(df)} rows)")

    # 3. Aggregations. Printed only — they're summaries, not row-level data.
    #    "by region" is the country substitution; country isn't meaningful
    #    for an NYC-only dataset.
    print("\n--- Average AQI by region (geo_type_name) ---")
    print("  Note: 'country' is not applicable - all rows are NYC.")
    print(df.groupby("geo_type_name")["data_value"].mean().round(2))

    print("\n--- Average AQI by city (geo_place_name) - first 15 ---")
    avg_by_city = df.groupby("geo_place_name")["data_value"].mean().round(2)
    print(avg_by_city.head(15))

    # 4. Add aqi_category via pd.cut. Vectorised, preserves order, and
    #    the labels become a Categorical so downstream filtering is cheap.
    df["aqi_category"] = pd.cut(
        df["data_value"], bins=AQI_BINS, labels=AQI_LABELS, right=False
    )

    # 5. Extract year and month — Silver guarantees start_date is datetime64.
    df["year"] = df["start_date"].dt.year
    df["month"] = df["start_date"].dt.month

    # 6. Monthly average trend.
    print("\n--- Monthly average AQI trend (year, month) ---")
    monthly_trend = (
        df.groupby(["year", "month"])["data_value"].mean().round(2).sort_index()
    )
    print(monthly_trend)

    # 7. Top-10 most polluted and top-10 least polluted cities, by mean PM2.5.
    sorted_by_city = avg_by_city.sort_values(ascending=False)
    print("\n--- Top 10 most polluted cities ---")
    print(sorted_by_city.head(10))
    print("\n--- Top 10 least polluted cities ---")
    print(sorted_by_city.tail(10).sort_values())

    # 8. Persist the row-level enriched DataFrame. The aggregations above
    #    are summaries; Stage 4 can re-aggregate from this row-level table.
    GOLD_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(GOLD_OUTPUT_PATH, index=False)
    print(f"\nSaved enriched dataset to: {GOLD_OUTPUT_PATH}")


if __name__ == "__main__":
    main()
