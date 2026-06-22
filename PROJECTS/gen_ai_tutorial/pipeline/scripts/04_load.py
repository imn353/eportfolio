"""04_load.py - Stage 4 of the pipeline.

Validates the Gold data, then loads it into the SQLite warehouse
(pipeline.db). This is the boundary where data leaves the file system
and enters the queryable warehouse — so we validate hard here and
refuse to load if anything looks wrong. "Better an empty DB than a
silently corrupt one."

Adaptations to the NYC dataset (carried forward from Stage 3):
    spec: 'country'    -> geo_type_name (no country in NYC-only data)
    spec: 'city'       -> geo_place_name
    spec: 'aqi value'  -> data_value (PM2.5 in mcg/m3)
"""

import sqlite3
import sys
from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parent.parent
GOLD_INPUT_PATH = PROJECT_ROOT / "data" / "gold" / "gold_data.csv"
DB_PATH = PROJECT_ROOT / "pipeline.db"

TABLE_NAME = "gold_air_quality"

# Key columns that must be non-null. Mapped from the spec's
# (country, city, aqi value) to the actual NYC schema.
KEY_COLUMNS = ["geo_type_name", "geo_place_name", "data_value"]

# The exact label set produced by 03_transform.py's pd.cut.
EXPECTED_CATEGORIES = {"Good", "Moderate", "Unhealthy", "Hazardous"}


def _report(name: str, passed: bool, detail: str = "") -> bool:
    # Single helper so every check reports with the same shape.
    status = "PASS" if passed else "FAIL"
    suffix = f" ({detail})" if detail else ""
    print(f"  [{status}] {name}{suffix}")
    return passed


def validate(df: pd.DataFrame) -> bool:
    print("Running validation checks ...")
    results = []

    # Check 1: no nulls in key columns.
    null_counts = df[KEY_COLUMNS].isna().sum()
    results.append(
        _report(
            "No nulls in key columns (geo_type_name, geo_place_name, data_value)",
            bool((null_counts == 0).all()),
            detail=f"nulls={null_counts.to_dict()}" if (null_counts != 0).any() else "",
        )
    )

    # Check 2: AQI (data_value) values are all positive numbers.
    aqi = df["data_value"]
    all_positive = pd.api.types.is_numeric_dtype(aqi) and bool((aqi > 0).all())
    results.append(
        _report(
            "AQI values are all positive numbers",
            all_positive,
            detail=f"min={aqi.min()}" if not all_positive else "",
        )
    )

    # Check 3: aqi_category contains only the 4 expected labels.
    observed = set(df["aqi_category"].dropna().unique())
    unexpected = observed - EXPECTED_CATEGORIES
    results.append(
        _report(
            "aqi_category contains only the 4 expected values",
            not unexpected,
            detail=f"unexpected={unexpected}" if unexpected else "",
        )
    )

    # Check 4: row count is greater than 0.
    results.append(
        _report(
            "Row count is greater than 0",
            len(df) > 0,
            detail=f"rows={len(df)}",
        )
    )

    return all(results)


def main() -> None:
    # 1. Load the Gold CSV. parse_dates keeps start_date as datetime so
    #    it lands in SQLite as a proper ISO string rather than the
    #    pre-stringified form.
    print(f"Loading {GOLD_INPUT_PATH} ...")
    df = pd.read_csv(GOLD_INPUT_PATH, parse_dates=["start_date"])

    # 2. Validate. If any check fails, refuse to load — we'd rather
    #    leave pipeline.db untouched than ingest bad data.
    if not validate(df):
        print("\nValidation failed - aborting load. pipeline.db left untouched.")
        sys.exit(1)
    print("\nAll checks passed.")

    # 3. Load into SQLite. if_exists='replace' gives us idempotent reruns:
    #    the table is dropped and recreated each time.
    #    sqlite3.connect() creates pipeline.db if it doesn't already exist.
    print(f"\nWriting {len(df)} rows to '{TABLE_NAME}' in {DB_PATH} ...")
    with sqlite3.connect(DB_PATH) as conn:
        df.to_sql(TABLE_NAME, conn, if_exists="replace", index=False)

        # 4. Verification query - read back what we just wrote, grouped
        #    by category, to confirm the round-trip looks right.
        print("\n--- Verification: row count by aqi_category ---")
        verify_df = pd.read_sql_query(
            f"SELECT aqi_category, COUNT(*) AS count "
            f"FROM {TABLE_NAME} GROUP BY aqi_category",
            conn,
        )
        print(verify_df.to_string(index=False))

    # 5. Final summary.
    print("\n--- Load summary ---")
    print(f"  Total rows loaded: {len(df)}")
    print(f"  Table name:        {TABLE_NAME}")
    print(f"  Database file:     {DB_PATH}")


if __name__ == "__main__":
    main()
