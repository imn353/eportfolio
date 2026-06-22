# Tutorial 4 — Air Quality Data Pipeline

A small multi-stage data engineering pipeline that ingests the OpenAQ Global
Air Quality Index dataset, cleans it, transforms it into analytic tables,
loads it into SQLite, and produces charts.

## Structure

```
tutorial4_pipeline/
├── data/
│   ├── raw/      # raw downloaded CSV
│   ├── silver/   # cleaned data
│   └── gold/     # transformed / aggregated data
├── scripts/
│   ├── 01_ingest.py
│   ├── 02_clean.py
│   ├── 03_transform.py
│   ├── 04_load.py
│   └── 05_visualise.py
├── output/
│   └── charts/   # generated plots
├── pipeline.db   # SQLite DB (created by 04_load.py — not committed)
└── README.md
```

## Pipeline stages

1. **01_ingest.py** — download the source CSV → `data/raw/raw_data.csv`.
2. **02_clean.py** — clean & normalise → `data/silver/`.
3. **03_transform.py** — aggregate & feature-engineer → `data/gold/`.
4. **04_load.py** — load gold tables into `pipeline.db` (SQLite).
5. **05_visualise.py** — query `pipeline.db` and write charts to `output/charts/`.

`pipeline.db` is **not** pre-created; step 04 generates it on first run.

## Setup

Requires Python 3.9+.

```
pip install pandas requests
```

## Run

```
python scripts/01_ingest.py
```

Then run the remaining stages in order as they are implemented.
