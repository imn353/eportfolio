"""02_clean.py — Stage 2 of the pipeline (Silver layer).

============================================================================
 Silver layer in the Medallion architecture
============================================================================
 The Medallion architecture organises a data lake into three tiers:

   Bronze  — raw, untouched data exactly as it was ingested.
   Silver  — cleaned, deduplicated, well-typed, with tidy column names.
             This is the "trustworthy" layer: every downstream consumer
             can assume the data is valid and consistent.
   Gold    — business-level aggregates and analytics tables, built on
             top of Silver.

 This script is the Bronze -> Silver transition. After it runs, the rest
 of the pipeline (transform, load, visualise) never has to worry about
 duplicates, messy column names, junk nulls, or stringly-typed dates.
============================================================================
"""

import re
from pathlib import Path

import pandas as pd

# Resolve paths off the script location so this works from any CWD.
PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_INPUT_PATH = PROJECT_ROOT / "data" / "raw" / "raw_data.csv"
SILVER_OUTPUT_PATH = PROJECT_ROOT / "data" / "silver" / "silver_data.csv"


def _normalise(name: str) -> str:
    # Lowercase + collapse any run of non-alphanumeric chars into a single underscore,
    # then strip leading/trailing underscores. "Unique ID" -> "unique_id".
    return re.sub(r"[^0-9a-zA-Z]+", "_", name).strip("_").lower()


def main() -> None:
    # 1. Load the raw snapshot produced by 01_ingest.py.
    print(f"Loading {RAW_INPUT_PATH} ...")
    df = pd.read_csv(RAW_INPUT_PATH)

    # 2. Profile the data BEFORE cleaning, with the original column names,
    #    so the user sees the actual messiness.
    print("\n--- Null counts per column ---")
    print(df.isna().sum())

    print("\n--- Duplicate row count ---")
    print(int(df.duplicated().sum()))

    print("\n--- Numeric column ranges (min / max) ---")
    numeric_cols = df.select_dtypes(include="number").columns
    for col in numeric_cols:
        print(f"  {col}: min={df[col].min()}, max={df[col].max()}")

    print("\n--- String column unique counts ---")
    # Include both "object" (legacy) and "str" (pandas 3+ string dtype).
    string_cols = df.select_dtypes(include=["object", "str"]).columns
    for col in string_cols:
        print(f"  {col}: {df[col].nunique()} unique values")

    # 3. Capture before-stats for the final summary.
    rows_before = len(df)
    nulls_before = int(df.isna().sum().sum())

    # 4. Standardise column names early so every subsequent step works
    #    against the stable silver schema.
    df.columns = [_normalise(c) for c in df.columns]

    # 5. Drop duplicate rows. Reassign rather than inplace=True to keep
    #    the data flow explicit.
    df = df.drop_duplicates()

    # 6. Drop columns where more than 50% of values are null — these
    #    carry too little signal to be worth imputing.
    null_frac = df.isna().mean()
    high_null_cols = null_frac[null_frac > 0.5].index.tolist()
    if high_null_cols:
        print(f"\nDropping high-null columns (>50% null): {high_null_cols}")
        df = df.drop(columns=high_null_cols)

    # 7. Fill remaining nulls. Re-select dtypes since the schema just changed.
    numeric_cols = df.select_dtypes(include="number").columns
    for col in numeric_cols:
        df[col] = df[col].fillna(df[col].median())

    string_cols = df.select_dtypes(include=["object", "str"]).columns
    for col in string_cols:
        df[col] = df[col].fillna("Unknown")

    # 8. Strip whitespace from string columns. Doing this AFTER fillna means
    #    we don't accidentally turn a NaN into the literal string "nan".
    for col in string_cols:
        df[col] = df[col].str.strip()

    # 9. Convert date/time columns. Gate on the column name containing "date"
    #    so we don't misinterpret labels like "time_period" ("Annual Average 2020").
    #    Require ~90% of non-null values to parse cleanly before committing,
    #    so a false-positive name match doesn't silently corrupt the column.
    for col in string_cols:
        if "date" not in col:
            continue
        parsed = pd.to_datetime(df[col], errors="coerce")
        non_null_before = df[col].notna().sum()
        non_null_after = parsed.notna().sum()
        if non_null_before > 0 and (non_null_after / non_null_before) >= 0.9:
            df[col] = parsed
            print(f"\nConverted '{col}' to datetime ({non_null_after}/{non_null_before} parsed).")

    # 10. Capture after-stats.
    rows_after = len(df)
    nulls_after = int(df.isna().sum().sum())

    # 11. Before/after summary.
    print("\n--- Before / After ---")
    print(f"Before: rows={rows_before:>7}  total_nulls={nulls_before}")
    print(f"After:  rows={rows_after:>7}  total_nulls={nulls_after}")

    # 12. Persist the cleaned DataFrame. index=False avoids a phantom
    #     "Unnamed: 0" column when downstream stages re-read the CSV.
    SILVER_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(SILVER_OUTPUT_PATH, index=False)

    print(f"\nSaved cleaned dataset to: {SILVER_OUTPUT_PATH}")


if __name__ == "__main__":
    main()
