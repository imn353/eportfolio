"""01_ingest.py — Stage 1 of the pipeline.

Downloads the OpenAQ Global Air Quality Index CSV, loads it into a pandas
DataFrame, inspects it, and writes a raw snapshot to data/raw/raw_data.csv.
"""

from io import StringIO
from pathlib import Path

import pandas as pd
import requests

# Source CSV: NYC Air Quality Surveillance Data. Small enough to fetch into memory.
DATASET_URL = "https://data.cityofnewyork.us/api/views/c3uy-2p5r/rows.csv"

# Resolve paths relative to the script so the pipeline runs from any CWD.
PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_OUTPUT_PATH = PROJECT_ROOT / "data" / "raw" / "raw_data.csv"


def main() -> None:
    # 1. Fetch the CSV over HTTP. timeout guards against a hung connection.
    print(f"Downloading dataset from {DATASET_URL} ...")
    response = requests.get(DATASET_URL, timeout=30)
    # Surface HTTP errors (404, 500, ...) instead of silently parsing an error page.
    response.raise_for_status()

    # 2. Parse the CSV from the in-memory response body via StringIO,
    #    so we don't need an intermediate temp file before pandas sees it.
    df = pd.read_csv(StringIO(response.text))

    # 3. Inspect the DataFrame.
    print("\n--- Shape ---")
    print(df.shape)

    print("\n--- Columns ---")
    print(df.columns.tolist())

    print("\n--- Dtypes ---")
    print(df.dtypes)

    print("\n--- Head (first 5 rows) ---")
    print(df.head(5))

    # 4. Make sure data/raw/ exists, then persist.
    #    index=False so re-reading later does not produce a phantom "Unnamed: 0" column.
    RAW_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(RAW_OUTPUT_PATH, index=False)

    print(f"\nSaved raw dataset to: {RAW_OUTPUT_PATH}")


if __name__ == "__main__":
    main()
